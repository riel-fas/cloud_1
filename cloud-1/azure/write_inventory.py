#!/usr/bin/env python3
"""Update exactly one host using JSON (valid YAML), preserving every other host."""
import json, sys
from pathlib import Path
import yaml

def update(outputs, parameters, alias, inventory):
    path = Path(inventory)
    data = yaml.safe_load(path.read_text()) if path.exists() else {}
    hosts = data.setdefault("all", {}).setdefault("children", {}).setdefault("web", {}).setdefault("hosts", {})
    p = parameters["parameters"]
    host = hosts.setdefault(alias, {})
    host.update(ansible_host=outputs["vmPublicIP"]["value"],
                domain_name=outputs["vmFqdn"]["value"],
                ansible_user=p["adminUsername"]["value"],
                admin_allowed_cidr=p["adminAllowedCidr"]["value"])
    temporary = path.with_suffix(".new")
    temporary.write_text(json.dumps(data, indent=2) + "\n")
    temporary.replace(path)

if __name__ == "__main__":
    update(json.loads(Path(sys.argv[1]).read_text()), json.loads(Path(sys.argv[2]).read_text()), sys.argv[3], sys.argv[4])
