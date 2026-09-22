#!/usr/bin/env bash
# Explicit opt-in only; default is offline help. Never run during local validation.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:---help}"
if [[ "$MODE" != "--preflight" && "$MODE" != "--apply" ]]; then
  echo "Usage: $0 --preflight|--apply SUBSCRIPTION_ID RESOURCE_GROUP parameters.json HOST_ALIAS"
  echo "Preflight reads Azure SKU/quota data; what-if requires an existing resource group."
  echo "Apply creates resources only after explicit confirmation. No automatic inventory overwrite."
  exit 0
fi
[[ $# == 5 ]] || { echo 'Expected five arguments.' >&2; exit 2; }
SUBSCRIPTION="$2"; RESOURCE_GROUP="$3"; PARAMS_FILE="$4"; HOST_ALIAS="$5"
[[ "$HOST_ALIAS" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]] || exit 2
command -v az >/dev/null
command -v python3 >/dev/null
read -r LOCATION VM_SIZE < <(python3 - "$PARAMS_FILE" <<'PYTHON'
import ipaddress,json,sys
p=json.load(open(sys.argv[1]))['parameters']
cidr=ipaddress.ip_network(p['adminAllowedCidr']['value'])
assert cidr.version == 4 and cidr.prefixlen == 32, 'Use the administrator IPv4 /32'
assert 'REPLACE' not in p['adminSshPublicKey']['value']
print(p['location']['value'],p['vmSize']['value'])
PYTHON
)
echo "[1/4] Checking selected subscription..."
az account show --subscription "$SUBSCRIPTION" --query '{name:name,state:state}' -o table
echo "[2/4] Checking ${VM_SIZE} availability in ${LOCATION} (up to 240 seconds)..."
python3 "$SCRIPT_DIR/run_check.py" --timeout 240 az vm list-skus --subscription "$SUBSCRIPTION" --location "$LOCATION" --size "$VM_SIZE" --resource-type virtualMachines --all --query "[?name=='${VM_SIZE}'].{Name:name,Restrictions:restrictions}" -o json
echo "[3/4] Reading regional and VM-family quotas (up to 120 seconds)..."
python3 "$SCRIPT_DIR/run_check.py" az vm list-usage --subscription "$SUBSCRIPTION" --location "$LOCATION" -o table
echo 'Review policy, regional AND family quota, SKU restrictions, credit expiry, and current prices.'
echo 'The commands above do not guarantee allocation capacity or sufficient credit.'
echo "[4/4] Checking whether resource group ${RESOURCE_GROUP} exists..."
EXISTS=$(python3 "$SCRIPT_DIR/run_check.py" az group exists --subscription "$SUBSCRIPTION" --name "$RESOURCE_GROUP")
if [[ "$MODE" == "--preflight" && "$EXISTS" != true ]]; then
  echo 'Resource group absent; no mutation performed. Run local Bicep compilation separately.'
  exit 0
fi
if [[ "$MODE" == "--apply" && "$EXISTS" != true ]]; then
  read -r -p "Type CREATE to create resource group ${RESOURCE_GROUP}: " CONFIRM
  [[ "$CONFIRM" == CREATE ]] || exit 1
  az group create --subscription "$SUBSCRIPTION" --name "$RESOURCE_GROUP" --location "$LOCATION" -o none
fi
az deployment group what-if --subscription "$SUBSCRIPTION" --resource-group "$RESOURCE_GROUP" --template-file "$SCRIPT_DIR/main.bicep" --parameters "@$PARAMS_FILE"
[[ "$MODE" == "--apply" ]] || exit 0
read -r -p 'Type DEPLOY to create billable Azure resources: ' CONFIRM
[[ "$CONFIRM" == DEPLOY ]] || exit 1
OUTPUT=$(mktemp)
trap 'rm -f "$OUTPUT"' EXIT
az deployment group create --subscription "$SUBSCRIPTION" --resource-group "$RESOURCE_GROUP" --template-file "$SCRIPT_DIR/main.bicep" --parameters "@$PARAMS_FILE" --query properties.outputs -o json > "$OUTPUT"
python3 "$SCRIPT_DIR/write_inventory.py" "$OUTPUT" "$PARAMS_FILE" "$HOST_ALIAS" "$SCRIPT_DIR/../ansible/inventories/hosts.yml"

echo "Deployment succeeded. Inventory updated for ${HOST_ALIAS}."
python3 - "$OUTPUT" <<'PYTHON'
import json,sys
o=json.load(open(sys.argv[1]))
print("Public IP:",o["vmPublicIP"]["value"])
print("DNS name:",o["vmFqdn"]["value"])
PYTHON
