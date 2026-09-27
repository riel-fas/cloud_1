#!/usr/bin/env python3
"""Focused regressions for false YAML passes and destructive inventory updates."""
import importlib.util, json, tempfile, unittest
from pathlib import Path
import yaml
from local_validate import ROOT, render, parse_yaml, environment
spec=importlib.util.spec_from_file_location('inventory_writer',ROOT/'azure/write_inventory.py')
writer=importlib.util.module_from_spec(spec);spec.loader.exec_module(writer)

class RegressionTests(unittest.TestCase):
    def test_invalid_yaml_rejected(self):
        with self.assertRaises(yaml.YAMLError):
            parse_yaml('key: [unterminated')

    def test_inventory_preserves_other_host(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'hosts.yml'
            other={'ansible_host':'192.0.2.20','domain_name':'second.example.com'}
            p.write_text(yaml.safe_dump({'all':{'children':{'web':{'hosts':{'secondary':other}}}}}))
            outputs={'vmPublicIP':{'value':'192.0.2.10'},'vmFqdn':{'value':'first.example.com'}}
            parameters={'parameters':{'adminUsername':{'value':'student'},'adminAllowedCidr':{'value':'198.51.100.1/32'}}}
            writer.update(outputs,parameters,'primary',p)
            hosts=yaml.safe_load(p.read_text())['all']['children']['web']['hosts']
            self.assertEqual(hosts['secondary'],other)
            self.assertEqual(hosts['primary']['ansible_host'],'192.0.2.10')
            before=p.read_text();writer.update(outputs,parameters,'primary',p)
            self.assertEqual(before,p.read_text())

    def test_acceptance_rejects_unhealthy(self):
        play=yaml.safe_load((ROOT/'ansible/validate.yml').read_text())[0]
        task=next(t for t in play['tasks'] if t['name']=='Assert exact running and health states')
        env=environment();env.filters['from_json']=json.loads
        for state, expected in [('healthy',True),('unhealthy',False),('starting',False)]:
            item={'stdout':json.dumps([{'State':{'Running':True,'Health':{'Status':state}}}])}
            passed=all(env.compile_expression(expr)(item=item) for expr in task['ansible.builtin.assert']['that'])
            self.assertEqual(passed,expected)

    def test_no_database_root_secret_in_wordpress(self):
        with tempfile.TemporaryDirectory() as d:
            render(d); cfg=yaml.safe_load((Path(d)/'docker-compose.yml').read_text())
            self.assertEqual(cfg['services']['wordpress']['secrets'],['db_password'])
            self.assertNotIn('secrets',cfg['services']['phpmyadmin'])
            self.assertNotIn('ports',cfg['services']['mariadb'])

if __name__=='__main__':unittest.main()
