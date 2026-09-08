# Changelog

## Unreleased

## 0.1.1

- Added FUNDING section and GitHub Sponsors/Patreon/Ko-fi badges
- Polished hex.pm metadata: keywords, description, links
- Created Elixir Forum post draft (`FORUM_POST.md`) and launch plan (`LAUNCH.md`)
- Added `demo.sh` for dummy-driver screencast
- Updated CI matrix: Elixir 1.17.3/1.18.4 × OTP 26.2/27.3
- Added `mix format --check-formatted` and `mix docs` to CI
- Added `credo` and `dialyxir` deps; CI runs both
- Added GitHub issue templates (bug, feature, driver request) and PR template
- Added `.gitattributes` for LF normalization
- Expanded `.gitignore` with IDE/OS entries
- Updated `SECURITY.md` with credential docs
- Fixed `production_guard` wording in CLI
- Removed non-existent `crucible await` CLI from forum post
- Corrected hex.pm description to match shipped drivers

## 0.1.0

- Libcloud-shaped `Crucible.Driver` (Dummy, Local, Docker, wrap Fly/K8s/EC2)
- `Crucible.HTTP` prefers Gale, injectable `:http` for tests
- Hetzner Cloud driver (`:hetzner`) — create/await/delete servers
- 100+ provider catalog (`Crucible.providers/0`); REST codecs: DigitalOcean, Vultr, Linode, Civo, Scaleway
- Data-driven `Crucible.Driver.REST.Json` — most VM names `boot` via HTTP templates
- AWS Signature V4 (`Crucible.Auth.SigV4`) for ECS/EKS/Lightsail/Fargate REST
- Standalone CLI: `mix crucible.binary` Burrito single file; else escript
- FOSS: MIT, CoC, CONTRIBUTING, SECURITY, FUNDING, Dependabot, CI
- Catalog driver returns `{:error, {:not_implemented, name}}` instead of pretending
- `Crucible.CloudInit` env → user_data
- `Crucible.FLAME.Backend`
