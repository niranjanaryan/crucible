# Security

Report vulnerabilities privately: GitHub Security Advisories on
[niranjanaryan/crucible](https://github.com/niranjanaryan/crucible), or via
[GitHub Sponsors](https://github.com/sponsors/niranjanaryan).

Do not file public issues for cloud tokens, SigV4, or provisioner credentials.

## Credentials

Crucible reads cloud provider credentials from three sources, in priority order:

1. Flags (`--token`, `--key`, etc.)
2. Environment variables (`HCLOUD_TOKEN`, `AWS_ACCESS_KEY_ID`, `GOOGLE_APPLICATION_CREDENTIALS`, ...)
3. `.env` in the current working directory (does not override existing shell vars)
4. `~/.config/crucible/config.yaml`
5. `crucible.yaml` in the current working directory

`.env` and YAML files should be added to `.gitignore`. Never commit tokens.

## CLI binary

The `mix crucible.install` command installs a Burrito-wrapped binary containing
ERTS. The binary reads credentials at runtime from the same sources; no tokens
are embedded at build time.

