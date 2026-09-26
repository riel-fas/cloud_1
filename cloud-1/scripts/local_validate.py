#!/usr/bin/env python3
"""Offline parsing and rendered Compose validation. No Docker daemon or Azure calls."""
import json, subprocess, tempfile
from pathlib import Path
import yaml
from jinja2 import Environment, StrictUndefined
ROOT = Path(__file__).resolve().parents[1]

def environment():
    env = Environment(undefined=StrictUndefined)
    env.filters['to_json'] = json.dumps
    return env

def variables(directory):
    v = yaml.safe_load((ROOT/'ansible/inventories/group_vars/all/vars.yml').read_text())
    base = str(directory)
    v.update(app_root=base, data_root=base+'/data', secret_root=base+'/secrets',
             cert_root=base+'/certs', nginx_conf_root=base+'/nginx', acme_root=base+'/acme',
             project_name='cloud1-local-check', domain_name='localhost',
             http_bind='127.0.0.1:18080:80', https_bind='127.0.0.1:18443:443')
    return v

def render(directory):
    directory = Path(directory)
    env = environment(); v = variables(directory)
    for d in ['data/wordpress','data/mariadb','certs','secrets','nginx/conf.d','acme']:
        (directory/d).mkdir(parents=True, exist_ok=True)
    for source, target in [('docker-compose.yml.j2','docker-compose.yml'),
                           ('nginx/nginx.conf.j2','nginx/nginx.conf'),
                           ('nginx/default.conf.j2','nginx/conf.d/default.conf')]:
        content = (ROOT/'ansible/roles/docker_stack/templates'/source).read_text()
        (directory/target).write_text(env.from_string(content).render(v)+'\n')
    return v

def parse_yaml(content):
    return list(yaml.safe_load_all(content))

def main():
    count = 0
    for p in (ROOT/'ansible').rglob('*.yml'):
        content = p.read_text()
        if content.startswith('$ANSIBLE_VAULT;'):
            print('SKIP encrypted file:',p.name); continue
        parse_yaml(content)
        count += 1
    for p in (ROOT/'ansible').rglob('*.j2'):
        environment().parse(p.read_text())
    with tempfile.TemporaryDirectory(prefix='cloud1-static-') as d:
        render(d)
        result = subprocess.run(['docker','compose','-f',d+'/docker-compose.yml','config','--format','json'],check=True,capture_output=True,text=True)
        cfg=json.loads(result.stdout)
        for name, service in cfg['services'].items():
            assert not service.get('env_file'), name
            if name != 'nginx': assert not service.get('ports'), name
        assert {p['target'] for p in cfg['services']['nginx']['ports']} == {80,443}
        assert cfg['networks']['backend']['internal'] is True
        assert not cfg['services']['phpmyadmin'].get('secrets')
        assert {s['source'] for s in cfg['services']['wordpress']['secrets']} == {'db_password'}
    for p in ROOT.rglob('*.sh'):
        subprocess.run(['bash','-n',str(p)],check=True)
    print(f'PASS: parsed {count} YAML files, Jinja templates, rendered Compose and shell syntax.')
    print('Not a deployment, security audit, or reboot/renewal test. Run Ansible checks and local integration separately.')

if __name__ == '__main__': main()
