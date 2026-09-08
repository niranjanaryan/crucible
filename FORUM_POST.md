# Crucible Forum Post Draft

## Title

**Crucible: boot VMs across AWS/Hetzner/DigitalOcean/Vultr/Linode from Elixir (Phoenix FLAME ready)**

## Body

Crucible is a new Hex package that brings multi-cloud VM provisioning to the Elixir ecosystem. It speaks the same Libcloud-shaped behaviour as Apache Libcloud (`boot`, `await`, `shutdown`, `describe`) but stays native to Erlang/OTP and ships a standalone CLI.

**Why it exists:** Phoenix FLAME needs a backend that can boot a runner, inject overlay env (Iroh/Zenoh), and shut it down — in ~3s, not minutes. Existing options are Fly-only (`FLAME.FlyBackend`), K8s-shaped, or IaC tools like Terraform that are too slow for per-call runners. Crucible fills the gap: one behaviour, many clouds, optional drivers.

**Install**

```bash
mix crucible.install
```

This prefers a Burrito single binary (ERTS bundled). Falls back to `mix escript.build` if Burrito is unavailable. Linux/macOS installs to `~/.local/bin`; Windows to `%LOCALAPPDATA%\elixcoder\bin`.

**CLI demo**

```bash
# list implemented drivers
crucible ls --implemented

# boot a dummy VM
crucible boot --driver dummy --name n1

# remove it
crucible rm --driver dummy --id dummy-1

# serve a provisioning HTTP API
crucible http
```

**Library usage (Phoenix FLAME)**

```elixir
{:ok, s} = Crucible.init(driver: :hetzner,
  token: System.fetch_env!("HCLOUD_TOKEN"),
  size: "cpx21", image: "ubuntu-24.04", region: "nbg1")

{:ok, machine, s} = Crucible.boot(s, %{
  env: %{"FLAME_PARENT" => "app@10.0.0.1", "IROH_BOOTSTRAP_TICKET" => "..."}
})

{:ok, machine, s} = Crucible.await(s, machine)
:ok = Crucible.shutdown(s, machine)
```

**Design choices**

- Erlang/OTP native. No Python NIF, no Terraform, no Mix runtime dependency for the CLI.
- Drivers are optional Mix deps. `{:crucible, "~> 0.1"}` pulls only the core behaviour, Local/Dummy, and HTTP client.
- Credentials from env, `.env`, or `~/.config/crucible/config.yaml`. Flags override.
- Join is not the driver's job. After IP is known, use classic `Node.connect`, Iroh tickets, or Zenoh client connects.

**Roadmap**

v1 ships with Local, Docker, Dummy, Hetzner, DigitalOcean, Vultr, Linode, Civo, Scaleway (REST), and Fly/K8s/EC2 wraps. GCP, Azure, Nomad, and ECS follow.

**Links**

- Hex: https://hex.pm/packages/crucible
- GitHub: https://github.com/niranjanaryan/crucible
- Docs: https://hexdocs.pm/crucible

If this is useful to your project, sponsoring helps keep the drivers maintained and new clouds added.

[GitHub Sponsors](https://github.com/sponsors/niranjanaryan) · [Patreon](https://patreon.com/niranjanaryan) · [Ko-fi](https://ko-fi.com/niranjanaryan)
