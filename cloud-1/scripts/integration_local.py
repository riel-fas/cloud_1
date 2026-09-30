#!/usr/bin/env python3
"""Disposable local Compose integration. Loopback only; never contacts Azure."""
import json, os, secrets, subprocess, tempfile, time
from pathlib import Path
from local_validate import render

def run(args, **kwargs):
    try:
        return subprocess.run(args, check=True, text=True, **kwargs)
    except subprocess.CalledProcessError as exc:
        print(exc.stdout or '', exc.stderr or '')
        raise

def main():
    with tempfile.TemporaryDirectory(prefix='cloud1-integration-', dir=Path(__file__).resolve().parents[2]) as temp:
        root = Path(temp); render(root)
        def compose(*args, **kwargs):
            return run(['docker','compose','-f',str(root/'docker-compose.yml'),*args],**kwargs)
        for name in ['db_password','db_root_password']:
            (root/'secrets'/name).write_text(secrets.token_hex(24))
            (root/'secrets'/name).chmod(0o444)
        run(['openssl','req','-x509','-nodes','-newkey','rsa:2048','-days','1',
             '-keyout',str(root/'certs/server.key'),'-out',str(root/'certs/server.crt'),
             '-subj','/CN=localhost','-addext','subjectAltName=DNS:localhost'],capture_output=True)
        try:
            compose('up','-d','--wait','--wait-timeout','240')
            compose('exec','-T','nginx','nginx','-t')
            # Execute the real Ansible initialization role locally, then rerun it.
            workspace=Path(__file__).resolve().parents[2]
            ansible=workspace/'.venv/bin/ansible-playbook'
            values=render(root)
            values.update(domain_name='localhost:18443', backup_root=str(root/'backups'),
                          vault_wp_admin_password=secrets.token_hex(20),
                          vault_wp_user_password=secrets.token_hex(20))
            extra=root/'test-vars.json';extra.write_text(json.dumps(values));extra.chmod(0o600)
            play=root/'init.yml'
            play.write_text('- hosts: localhost\n  connection: local\n  gather_facts: false\n  roles: [wordpress_init]\n')
            env=os.environ.copy()
            env.update(LANG='en_US.UTF-8',LC_ALL='en_US.UTF-8',
                       ANSIBLE_HOME=str(workspace/'.ansible'),
                       ANSIBLE_COLLECTIONS_PATH=str(workspace/'.collections'),
                       ANSIBLE_ROLES_PATH=str(workspace/'cloud-1/ansible/roles'))
            for iteration in range(2):
                result=run([str(ansible),'-i','localhost,',str(play),'-e','@'+str(extra)],env=env,capture_output=True)
                print(result.stdout)
                if iteration == 1:
                    assert 'changed=0' in result.stdout, result.stdout
            inventory=root/'local-inventory.yml'
            inventory.write_text('web:\n  hosts:\n    localhost:\n      ansible_connection: local\n')
            result=run([str(ansible),'-i',str(inventory),str(workspace/'cloud-1/ansible/backup.yml'),
                        '-e','@'+str(extra),'-e','ansible_become=false'],env=env,capture_output=True)
            print(result.stdout)
            dumps=list((root/'backups').glob('*.sql'))
            assert len(dumps)==1 and 'CREATE TABLE' in dumps[0].read_text()
            compose('run','--rm','wpcli','post','create','--post_title=Persistence probe','--post_status=publish')
            (root/'data/wordpress/wp-content/uploads').mkdir(exist_ok=True)
            (root/'data/wordpress/wp-content/uploads/persistence.txt').write_text('retained')
            def http_checks():
                for path, marker in [('/', 'Cloud-1 Inception on Azure'),('/phpmyadmin/','phpMyAdmin')]:
                    response=run(['curl','--fail','--silent','--show-error','-k','https://localhost:18443'+path],capture_output=True)
                    assert marker in response.stdout, (path,'missing expected response')
                headers=run(['curl','-sSI','http://127.0.0.1:18080/'],capture_output=True).stdout
                assert '301' in headers and 'https://localhost/' in headers
                for path in ['/.env','/.git/config','/wp-content/uploads/test.php']:
                    status=run(['curl','-ks','-o','/dev/null','-w','%{http_code}','https://localhost:18443'+path],capture_output=True).stdout
                    assert status in ['403','404'],(path,status)
            http_checks()
            before=compose('ps','-q',capture_output=True).stdout
            compose('up','-d','--wait')
            assert compose('ps','-q',capture_output=True).stdout == before, 'repeat up recreated containers'
            compose('down')
            compose('up','-d','--wait','--wait-timeout','240')
            http_checks()
            posts=compose('run','--rm','wpcli','post','list','--field=post_title',capture_output=True).stdout
            assert 'Persistence probe' in posts
            assert (root/'data/wordpress/wp-content/uploads/persistence.txt').read_text()=='retained'
            db=json.loads(run(['docker','inspect','cloud1-local-check-mariadb'],capture_output=True).stdout)[0]
            assert not db['HostConfig']['PortBindings']
            print('PASS: startup, HTTP/HTTPS routing, phpMyAdmin, real Ansible WordPress initialization and repeat idempotency, backup, repeat Compose, recreation and persistence.')
            print('Host reboot, full Ubuntu Ansible execution, ACME renewal and Azure networking remain separate checks.')
        finally:
            compose('down','--volumes','--remove-orphans')

if __name__=='__main__':main()
