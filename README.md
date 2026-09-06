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
# from this repo
mix crucible.install
# Linux/macOS: ~/.local/bin    Windows: %LOCALAPPDATA%\elixcoder\bin
# needs escript (Erlang/OTP) on PATH

crucible ls --implemented
crucible boot --driver dummy --name n1
crucible sizes --driver dummy
crucible rm --driver dummy --id dummy-1
crucible http
crucible version
```

Needs Erlang/OTP on PATH (escript). Not Mix. Host apps can still `mix crucible …` or `{:crucible, "~> 0.1"}`.

```elixir
{:ok, s} = Crucible.init(driver: :hetzner, token: System.fetch_env!("HCLOUD_TOKEN"),
  size: "cpx21", image: "ubuntu-24.04", region: "nbg1")
{:ok, m, s} = Crucible.boot(s, %{env: %{"FLAME_PARENT" => "..."}})
{:ok, m, s} = Crucible.await(s, m)
:ok = Crucible.shutdown(s, m)
```

MIT.
