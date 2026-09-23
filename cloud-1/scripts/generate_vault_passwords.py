#!/usr/bin/env python3
"""Ansible Vault editor: replace bootstrap passwords without printing their values.

Use only before the first successful deployment. Existing database/account passwords
must be rotated explicitly rather than regenerated using this helper.
"""
import os
from pathlib import Path
import secrets
import sys
import yaml

PASSWORD_KEYS = (
    'vault_db_root_password',
    'vault_db_password',
    'vault_wp_admin_password',
    'vault_wp_user_password',
)


def replace_passwords(path):
    path = Path(path)
    text = path.read_text()
    if text.startswith('$ANSIBLE_VAULT;'):
        raise ValueError('Use this helper through ansible-vault edit, not on encrypted files directly.')
    data = yaml.safe_load(text) or {}
    if not isinstance(data, dict):
        raise ValueError('Vault must contain a YAML mapping. No changes made.')
    for key in PASSWORD_KEYS:
        data[key] = secrets.token_hex(24)
    os.chmod(path, 0o600)
    path.write_text(yaml.safe_dump(data, sort_keys=False, default_style="'"))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('Invoke through EDITOR with ansible-vault edit; see README.')
    replace_passwords(sys.argv[1])
    print('Generated four independent 48-character passwords. Values were not printed.')
