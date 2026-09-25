#!/usr/bin/env bash
# ==============================================================================
# Cloud-1 Mock Vault Generator for Local Testing
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_DEST="${SCRIPT_DIR}/../examples/vault.local-test.yml"
VAULT_EXAMPLE="${SCRIPT_DIR}/../examples/vault.example.yml"

if [ -f "${VAULT_DEST}" ]; then
    echo "[!] File ${VAULT_DEST} already exists. Skipping creation."
    exit 0
fi

echo "[+] Generating testing vault at ${VAULT_DEST}..."
sed -e "s/REPLACE_WITH_STRONG_DB_ROOT_PASSWORD/mock_db_root_$(openssl rand -hex 8)/" \
    -e "s/REPLACE_WITH_STRONG_DB_USER_PASSWORD/mock_db_user_$(openssl rand -hex 8)/" \
    -e "s/REPLACE_WITH_STRONG_WP_ADMIN_PASSWORD/mock_wp_admin_$(openssl rand -hex 8)/" \
    -e "s/REPLACE_WITH_STRONG_WP_USER_PASSWORD/mock_wp_user_$(openssl rand -hex 8)/" \
    -e "s/REPLACE_WITH_32_CHAR_RANDOM_STRING_FOR_PHPMYADMIN/$(openssl rand -hex 16)/" \
    "${VAULT_EXAMPLE}" > "${VAULT_DEST}"

chmod 600 "${VAULT_DEST}"
echo "[+] Testing vault created with dummy random values and strict permissions (0600)."
echo "    TEST ONLY: This file is not loaded by deployment automatically."
echo "    ansible-vault encrypt ${VAULT_DEST}"
