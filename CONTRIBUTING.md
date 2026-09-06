# Contributing

## Setup

Elixir **1.17+**, OTP **27+**. No Zig NIF.

```bash
mix deps.get
mix test
mix docs
mix crucible.install
```

## Scope

* Multi-cloud provisioner (`Crucible.Driver`)
* CLI: `crucible` escript / `mix crucible`
* FLAME backend that boots machines; Iroh/Zenoh join is Ingot/Dusk/Zeiroh

## Hex

Path deps are omitted when `HEX_PUBLISH=1`. See `PUBLISH.md`.
