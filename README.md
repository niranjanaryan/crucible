# Crucible

[![Hex.pm](https://img.shields.io/hexpm/v/crucible.svg)](https://hex.pm/packages/crucible)
[![Hexdocs](https://img.shields.io/badge/hex-docs-purple.svg)](https://hexdocs.pm/crucible)
[![CI](https://github.com/niranjanaryan/crucible/actions/workflows/ci.yml/badge.svg)](https://github.com/niranjanaryan/crucible/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub-ea4aaa.svg)](https://github.com/sponsors/niranjanaryan)

Multi-cloud **provisioner** for Phoenix FLAME. One behaviour; many clouds.
**Zeiroh** is the FLAME overlay (Iroh/Zenoh). Ingot/dusk **join** nodes.
Crucible **creates** the box.

See **[DESIGN.md](DESIGN.md)** for the survey of Fly/K8s/EC2/Gigalixir,
libcluster, and Apache Libcloud — and why this is a new package.

```elixir
{:crucible, "~> 0.1"}
{:flame, "~> 0.5"}

{FLAME.Pool,
 backend: {Crucible.FLAME.Backend, driver: :local}}  # :docker | :fly | :k8s | ...
```

`Crucible.providers/0` lists **100+** clouds. Almost every VM name is
JSON REST (`boot` issues real HTTP). Named codecs: Hetzner, DO, Vultr,
Linode, Civo, Scaleway. Wraps: Fly/K8s/EC2. PaaS/storage stay
`{:not_implemented, name}`.

## CLI (same idea as Orian)

```bash
# from this repo
mix crucible.install          # ~/.local/bin/crucible

crucible ls --implemented
crucible boot --driver dummy --name n1
crucible sizes --driver dummy
crucible rm --driver dummy --id dummy-1
crucible http
crucible version
```

Inside a Mix project that depends on Crucible: `mix crucible boot --driver dummy` (same CLI).

```elixir
{:ok, s} = Crucible.init(driver: :hetzner, token: System.fetch_env!("HCLOUD_TOKEN"),
  size: "cpx21", image: "ubuntu-24.04", region: "nbg1")
{:ok, m, s} = Crucible.boot(s, %{env: %{"FLAME_PARENT" => "..."}})
{:ok, m, s} = Crucible.await(s, m)
:ok = Crucible.shutdown(s, m)
```

MIT.
