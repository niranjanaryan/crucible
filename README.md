# Crucible

[![Hex.pm](https://img.shields.io/hexpm/v/crucible.svg)](https://hex.pm/packages/crucible)
[![Hexdocs](https://img.shields.io/badge/hex-docs-purple.svg)](https://hexdocs.pm/crucible)
[![CI](https://github.com/niranjanaryan/crucible/actions/workflows/ci.yml/badge.svg)](https://github.com/niranjanaryan/crucible/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub-ea4aaa.svg)](https://github.com/sponsors/niranjanaryan)

Standalone multi-cloud **provisioner** CLI (same shape as **orian**), plus a library for Phoenix FLAME. Crucible **creates** the box. Zeiroh joins (Iroh/Zenoh). Gale is HTTP/3.

```
gale     — Phoenix HTTP/3
orian    — parallel S3/S5 transfer CLI
crucible — boot/rm VMs across clouds (this)
ingot    — Iroh + Zenoh cluster
dusk     — Zenoh-first cluster
zeiroh   — Phoenix FLAME overlay
```

```bash
# from this repo (preferred — Burrito binary bundles ERTS)
mix crucible.install

# or build the escript fallback (requires Erlang/OTP on PATH)
mix escript.build

# Linux/macOS: ~/.local/bin    Windows: %LOCALAPPDATA%\elixcoder\bin

crucible ls --implemented
crucible boot --driver dummy --name n1
crucible sizes --driver dummy
crucible rm --driver dummy --id dummy-1
crucible http
crucible version
```

As a library dependency (`{:crucible, "~> 0.1"}`), the CLI install task is not inherited — clone the repo or use the published escript for the standalone binary.

Credentials from **env**, **`.env`**, or **`crucible.yaml`** (flags override):

```yaml
# crucible.yaml
driver: hetzner
region: nbg1
size: cpx21
# token: "…"   or HCLOUD_TOKEN in .env
hetzner:
  token: "…"
```

```
# .env  (does not override vars already in the shell)
HCLOUD_TOKEN=…
AWS_ACCESS_KEY_ID=…
```

`--config path` / `--env-file path` if the files are not in cwd. Also `~/.config/crucible/config.yaml`.

Host apps can still `mix crucible …` or `{:crucible, "~> 0.1"}`.

```elixir
{:ok, s} = Crucible.init(driver: :hetzner, token: System.fetch_env!("HCLOUD_TOKEN"),
  size: "cpx21", image: "ubuntu-24.04", region: "nbg1")
{:ok, m, s} = Crucible.boot(s, %{env: %{"FLAME_PARENT" => "..."}})
{:ok, m, s} = Crucible.await(s, m)
:ok = Crucible.shutdown(s, m)
```

## FUNDING

If Crucible is useful to your project, consider sponsoring the project to support ongoing development.

[![Sponsor](https://img.shields.io/badge/sponsor-GitHub-ea4aaa.svg)](https://github.com/sponsors/niranjanaryan)
[![Sponsor](https://img.shields.io/badge/sponsor-Patreon-F96854.svg)](https://patreon.com/niranjanaryan)
[![Sponsor](https://img.shields.io/badge/sponsor-Ko--fi-FF5E5B.svg)](https://ko-fi.com/niranjanaryan)
[![Buy Me a Coffee](https://img.shields.io/badge/buy%20me%20a%20coffee-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/niranjanaryan)

MIT.

