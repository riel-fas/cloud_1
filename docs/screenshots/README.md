# Screenshot files

Place the actual captures described in [the checklist](../screenshots.md) here.

Added:

- [01-wordpress-https.png](01-wordpress-https.png): the deployed WordPress homepage.
- [02-tls-certificate.png](02-tls-certificate.png): browser confirmation of a secure connection and valid certificate. Issuer and validity dates are not shown in this capture.
- [04-containers.png](04-containers.png): four healthy containers, with host ports published only for Nginx.
- [05-phpmyadmin.png](05-phpmyadmin.png): the WordPress database structure and its 12 tables, without record contents.
- [06-azure-network-rules.png](06-azure-network-rules.png): inbound SSH, HTTP and HTTPS rules. The SSH source is hidden, so its CIDR restriction is not visible.
- [07-acceptance-recap.png](07-acceptance-recap.png): successful application validation, with `ok=9`, `changed=0`, `unreachable=0` and `failed=0`.
- [08-second-deployment.png](08-second-deployment.png): successful full deployment rerun, with `ok=53`, `changed=1`, `unreachable=0` and `failed=0`. The single change was the apt cache refresh.
- [09a-before-reboot.png](09a-before-reboot.png): published persistence-test post and uploaded image before reboot.
- [09b-after-reboot.png](09b-after-reboot.png): the same post and image displayed after reboot.
- [09c-after-reboot-containers.png](09c-after-reboot-containers.png): new boot ID and all four containers healthy after reboot.

Use the numbered filenames from the checklist, review each image for secrets and personal details, and then embed the relevant files in the root README. Do not add generated or staged images as evidence of tests that were not performed.
