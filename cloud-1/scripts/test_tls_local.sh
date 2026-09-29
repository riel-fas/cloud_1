#!/usr/bin/env bash
# ==============================================================================
# Cloud-1 Local TLS Certificate and OpenSSL Handshake Tester
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/../.tmp_tls_test"

echo "=== Testing TLS Certificate Generation with Subject Alternative Names (SAN) ==="
mkdir -p "${TEST_DIR}"

# 1. Generate test SAN config
cat << 'EOF' > "${TEST_DIR}/openssl_san.cnf"
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C = FR
ST = Paris
L = Paris
O = 42School
OU = Cloud-1
CN = cloud1.local

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = cloud1.local
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

# 2. Generate certificate and private key
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout "${TEST_DIR}/server.key" \
    -out "${TEST_DIR}/server.crt" \
    -config "${TEST_DIR}/openssl_san.cnf" >/dev/null 2>&1

echo "[+] Certificate and 4096-bit RSA key generated successfully."

# 3. Verify certificate details using OpenSSL
echo "[+] Validating Certificate Subject and SAN extensions..."
CERT_TEXT=$(openssl x509 -in "${TEST_DIR}/server.crt" -text -noout)

if echo "${CERT_TEXT}" | grep -q "DNS:cloud1.local" && echo "${CERT_TEXT}" | grep -q "IP Address:127.0.0.1"; then
    echo "  [PASS] Certificate contains valid SAN: DNS:cloud1.local and IP:127.0.0.1"
else
    echo "  [FAIL] Missing expected SAN entries!"
    exit 1
fi

if echo "${CERT_TEXT}" | grep -qi "Public-Key: (4096 bit)"; then
    echo "  [PASS] RSA Key strength verified: 4096 bit."
else
    echo "  [FAIL] Key is not 4096-bit!"
    exit 1
fi

# Cleanup test directory
rm -rf "${TEST_DIR}"
echo "=== TLS Local Verification Complete: All Checks Passed ==="
