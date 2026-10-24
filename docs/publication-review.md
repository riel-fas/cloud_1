# Public repository review

Reviewed on October 24, 2026, before changing repository visibility.

## Scope and findings

Reviewed the 84 tracked files present at the start of the review, including Cloud-1 configuration and scripts, the Inception reference project, documentation, screenshot contents and metadata, and PDF metadata. A custom pattern scan covered 93 blobs reachable from all local Git refs, including the local backup ref. It looked for private keys, common provider tokens, signed Azure URLs, credential assignments, email addresses and sensitive filenames. Matches for credential assignments were templates or documented test values.

No production vault, inventory, Azure parameter file, private key, provider token or database dump was found in that reachable history. Real local deployment files remain ignored. The encrypted production vault was not decrypted. This is a scoped review, not a guarantee that every possible secret format is detected; unreferenced objects, GitHub issues, Actions logs, releases and other remote-only content were not audited.

## Corrections

- Removed password printing from the reference FTP startup script.
- Added ignore rules for secret directories, database dumps, Terraform state, Azure CLI state and temporary inventory output.
- Replaced the Azure example SSH key with an explicit RSA-key placeholder matching the setup instructions.
- Corrected the reference README's claim that its Compose stack mounts Docker secrets. That stack uses environment variables and exposes extra services; it is not the Azure deployment.
- Configured Ansible lint to use example credentials and exclude local production files.
- Rejected the published mock passwords in the deployment prechecks, with a regression test.
- Corrected stale test statuses and the comment describing mutable image tags.

## Information that will become public

- Git author and committer metadata contains a personal email address. Changing a file or a GitHub profile setting does not remove addresses from existing commits. No history rewrite was performed in this review.
- Screenshots show browser bookmarks, the public application hostname, usernames and some desktop details. No passwords or database record contents were visible in the supplied captures. The Azure screenshot hides the SSH source address.
- Screenshots contain capture metadata such as dimensions, tool information and comments. The metadata scan did not flag email addresses, local user paths or GPS field names in the text chunks; it is not a complete forensic metadata audit.
- The project subject PDF and uploaded game screenshot are included. Check that you want to distribute these materials along with the project. No repository license was selected during this review.

## Verification

- Local YAML/Jinja/Compose/shell checks: passed.
- Five regression tests, including rejection of public mock credentials: passed.
- Ansible lint, basic profile, using example vault: passed.
- Bicep compilation: passed.
- Local TLS generation and SAN/key checks: passed.
- Changed shell script syntax and Git whitespace checks: passed.
- Ignore rules for local credentials, secret files and dumps: verified.

No Azure deployment, reboot, credential rotation or repository visibility change was performed. Changes to the deployment prechecks take effect on the next playbook run. The reference FTP fix does not affect the running Azure stack.

The remaining runtime checks are listed in the [readiness report](../cloud-1/READINESS_REPORT.md). Dependency CVEs, image vulnerability scanning, external network probing and penetration testing were outside this review.
