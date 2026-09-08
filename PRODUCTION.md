# Production plan — Crucible (and FLAME overlay)

Status: **not production for elastic FLAME**. The CLI and Hetzner/DO-class
REST can be used for **controlled boot/rm** if you treat tokens as secrets.
Remote `FLAME.call` still needs a real terminator + provisioner wrap.

## What is true in prod today

| Layer | Production? | Notes |
|---|---|---|
| Standalone CLI escript | yes for local ops | `mix crucible.install`; OTP on PATH |
| `.env` / `crucible.yaml` | yes | flags > file > dotenv (fill-only) |
| Dummy / local / docker | yes (dev) | no cloud bill |
| Hetzner + named REST codecs | **beta** | real HTTP + token; test against a cheap VM first |
| Fly / K8s / EC2 wraps | **beta** | need `flame` / `flame_k8s_backend` / `flame_ec2` in the **host app**, not the escript |
| JSON REST for 100+ names | **no** | templates; many 401/404 |
| AWS SigV4 | **beta** | headers work; ECS JSON body is not RunTask |
| GCP/Azure/OCI OAuth | **no** | |
| Zeiroh `FLAME.Pool` | **no** | local Task unless Crucible + terminator_sup |
| Iroh/Zenoh live mesh | **no** | stubs without `iroh_beam` / `zenohex` |

## Production allowlist (CLI `--production`)

Only these may boot without `--force`:

`dummy`, `local`, `docker`, `hetzner`, `digitalocean`, `vultr`, `linode`,
`civo`, `scaleway`, `fly`, `k8s`, `ec2`

Everything else is catalog/experiment.

## Ordered work

1. **This slice** — allowlist, HTTP retry, secret file hygiene, CI, example config.
2. **Live soak** — one Hetzner CX and one DO droplet: boot, await IP, ssh/cloud-init env, rm.
3. **FLAME attach** — `@behaviour FLAME.Backend`, `FLAME.Terminator`, `FLAME_PARENT` in user_data; Zeiroh `provisioner: :hetzner`.
4. **Fly wrap in host app** — document runtime.exs; do not stuff Fly into the escript.
5. **AWS** — either keep `FlameEC2` wrap or a real RunInstances/RunTask codec (not generic JSON).
6. **GCP/Azure** — OAuth client-credentials / ADC; do not ship until signed.
7. **Iroh/Zenoh** — live membership after nodes exist; zenohd as infra, not a FLAME runner.
8. **Hex publish** — gale, ingot, dusk, crucible, zeiroh when (3) has a test under `FLAME.Pool`.

## Ops rules

- Never commit `crucible.yaml` with tokens; use `.env` (gitignored) or a secret manager.
- Config files should be mode `0600`.
- Prefer env `HCLOUD_TOKEN` over YAML `token:`.
- Cap `FLAME.Pool` `max:` with a cloud quota, not overlay gossip.
- Run zenohd / iroh-relay as always-on services; FLAME min can be 0.

## Out of scope for v1 prod

Kind, Terraform for `FLAME.call`, mixing `iroh_beam` + `zenohex` in one lock,
public n0 relays as capacity.
