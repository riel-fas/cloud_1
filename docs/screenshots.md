# Screenshots for the README

Capture the real running project. A screenshot should show a result that a reviewer can understand, not a long terminal transcript or the whole Azure portal. Keep the relevant URL, command, service names and result visible. Crop unrelated browser tabs and personal account details.

The first Azure deployment and trusted HTTPS have completed. The remaining test screenshots should be taken only after the corresponding tests pass.

## Capture now

| Filename | Where to go | What to show |
|---|---|---|
| `01-wordpress-https.png` | Open the WordPress homepage | Site title, an actual post and uploaded image, and the HTTPS URL. Create a sample post first if the page is still empty. |
| `02-tls-certificate.png` | Browser site controls, connection details, certificate viewer | Domain, certificate issuer and validity dates. The icon is not necessarily a padlock in every browser. |
| `03-deployment-recap.png` | Terminal after `site.yml` | The completion message and recap showing `failed=0` and `unreachable=0`. The first successful TLS run reported `ok=54`, `changed=5`. |
| `04-containers.png` | SSH into the VM; run `sudo docker compose -f /opt/cloud-1/docker-compose.yml ps` | Four running services, health status and only web ports published on Nginx. |
| `05-phpmyadmin.png` | Open `/phpmyadmin/`, sign in with the application database user | The WordPress database and its table names. Avoid browsing user records, password hashes or session data in the screenshot. |
| `06-azure-network-rules.png` | Azure Portal, search `cloud1-nsg`, open inbound security rules | SSH limited to a `/32` source, HTTP 80 and HTTPS 443. Redact the personal source IP if publishing it is unnecessary. |

## Capture after validation

| Filename | Required test | What the screenshot should establish |
|---|---|---|
| `07-acceptance-recap.png` | Run `validate.yml` | Acceptance playbook completed with no failed or unreachable hosts. |
| `08-second-deployment.png` | Run `site.yml` again after TLS setup | Repeat-deployment recap. If it reports changes, inspect and explain them; do not edit the output to show zero. |
| `09a-before-reboot.png`, `09b-after-reboot.png`, `09c-after-reboot-containers.png` | Save a post, image and account; reboot the VM and check them again | The same saved content after reboot. Keep a short written before/after record; a single screenshot cannot prove the entire sequence. |
| `10-parallel-deployment.png` | Deploy to two independent hosts in one Ansible run | Both distinct inventory hosts in the successful recap. |
| `11-backup-restore.png` | Restore a backup into a separate test instance | Restored content and the verification result. A backup file listing alone is not evidence of successful restoration. |

Do not take screenshots of `ansible-vault view`, private keys, passwords, session cookies, access tokens or runtime secret files. Hide subscription IDs and personal email addresses in Azure portal captures. A public application hostname can remain visible.

## Add the images to the README

Save them in `docs/screenshots/`. Once the files exist, add a short caption and a relative image link to the root README:

```markdown
The homepage is served through Nginx with a trusted certificate.

![WordPress homepage over HTTPS](docs/screenshots/01-wordpress-https.png)
```

Use only a few images in the main README: the homepage, deployment recap, containers, phpMyAdmin and network rules are a useful starting set. Link to the other evidence where appropriate rather than filling the README with full-page captures.

Screenshots supplement live checks. They do not replace the evaluator's ability to redeploy, reboot the server or test network access.
