# Changelog

## 0.1.0

- Libcloud-shaped `Crucible.Driver` (Dummy, Local, Docker, wrap Fly/K8s/EC2)
- `Crucible.HTTP` prefers Gale, injectable `:http` for tests
- Hetzner Cloud driver (`:hetzner`) — create/await/delete servers
- 100+ provider catalog (`Crucible.providers/0`); REST codecs: DigitalOcean, Vultr, Linode, Civo, Scaleway
- Data-driven `Crucible.Driver.REST.Json` — most VM names `boot` via HTTP templates
- AWS Signature V4 (`Crucible.Auth.SigV4`) for ECS/EKS/Lightsail/Fargate REST
- Standalone CLI: `mix crucible.install` → `~/.local/bin/crucible`
- FOSS: MIT, CoC, CONTRIBUTING, SECURITY, FUNDING, Dependabot, CI
- Catalog driver returns `{:error, {:not_implemented, name}}` instead of pretending
- `Crucible.CloudInit` env → user_data
- `Crucible.FLAME.Backend`
