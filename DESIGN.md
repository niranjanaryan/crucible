# Crucible — multi-cloud FLAME provisioner (design)

Elixir has **no Apache Libcloud**. Each cloud’s FLAME/libcluster package
boots **one** API. Crucible is a new Hex library: one behaviour, many
HTTP drivers, used by Ingot/Zeiroh as `provisioner: {Crucible, driver: :hetzner}`.

Status: design + skeleton. Do not treat drivers as production until each
has a live create/destroy test.

Apache Libcloud object model (Node, Size, Image, Location, NodeState,
Dummy driver, `get_driver`): [LIBCLOUD.md](LIBCLOUD.md). Do not bind
the Python library.

## What exists online (do not reimplement blindly)

### FLAME backends (create a runner, then Erlang dist)

| Package | Cloud | Notes |
|---|---|---|
| `FLAME.FlyBackend` | Fly Machines | In `flame`; ~3s; same Docker image |
| `flame_k8s_backend` | Any K8s | Copy parent pod; 133★ |
| `flame_ec2` | AWS EC2 | S3 mix release tarball; no Docker required |
| `flame_gigalixir_backend` | Gigalixir | Uses libcluster Kubernetes under the PaaS |
| ECS (reddit, not Hex) | AWS ECS `RunTask` | Same VPC; poll RUNNING + private IP |
| `flame_slurm_backend` | HPC Slurm | Hex dependent of `flame`; batch jobs, not VMs |

Chris McCord: any host with “boot this image” is a valid backend. The
entire Fly backend is ~200 LOC + `Req`.

### libcluster (discover, does **not** create VMs)

Kubernetes, Gossip, EPMD, DNSPoll; third-party: EC2 tags, GCE instance
groups, Hetzner labels (`libcluster_hcloud`), DigitalOcean droplets,
Postgres (Supabase, cloud-agnostic **join**).

Use these **after** Crucible boots a node, or skip them if Iroh dist /
Zenoh membership is the join path.

### Generic compute APIs (Python / IaC — too slow or wrong language)

| Tool | Role vs FLAME |
|---|---|
| Apache **Libcloud** | `create_node` / `destroy_node` — **the model to copy in Elixir** |
| Terraform / Pulumi | Minutes, state file; not 3s runners |
| Crossplane / Cluster API | K8s-shaped; use `flame_k8s_backend` instead |

Do **not** shell out to Terraform for `FLAME.call`.

## Gap

There is no Hex package that:

1. Implements `FLAME.Backend`
2. Speaks **many** clouds through one `boot/1` / `shutdown/1`
3. Injects `FLAME_PARENT` + Iroh/Zenoh env
4. Lets the host enable **one** driver without locking every SDK

That is Crucible.

## Package split

```
crucible          behaviour + Local + Docker + Dummy + Crucible.HTTP (Gale) + FLAME adapter
crucible_fly      thin wrap of FLAME.FlyBackend   (optional)
crucible_k8s      thin wrap of FLAMEK8sBackend
crucible_ec2      thin wrap of FlameEC2
crucible_hetzner  Hetzner Cloud POST /servers     (Gale/HTTP)
crucible_do       DigitalOcean Droplets
crucible_vultr    Vultr instances (Libcloud has this; we do not wrap Python)
crucible_linode   Linode / Akamai
crucible_slurm    wrap `flame_slurm_backend`
crucible_gcp      Compute Engine instances.insert
crucible_azure    Azure Compute VMs
crucible_render   Render private services (if API allows one-shot)
crucible_railway  Railway
crucible_nomad    Nomad job dispatch
crucible_ecs      ECS RunTask
```

v1 ships **crucible** with a 100+ name catalog, REST codecs for
Hetzner/DO/Vultr/Linode/Civo/Scaleway, wraps for Fly/K8s/EC2, and
honest `{:not_implemented, name}` for the rest. Optional Mix deps stay
out of the default lock. Zeiroh/Ingot set `provisioner:` / `driver:`.

## Behaviour (Libcloud-shaped, FLAME-shaped)

```elixir
defmodule Crucible.Driver do
  @type spec :: %{
          optional(:image) => String.t(),
          optional(:size) => String.t(),
          optional(:region) => String.t(),
          optional(:env) => %{String.t() => String.t()},
          optional(:user_data) => String.t(),
          optional(:tags) => map()
        }

  @callback init(Keyword.t()) :: {:ok, term()} | {:error, term()}
  @callback boot(state, spec) :: {:ok, Crucible.Machine.t(), state} | {:error, term()}
  @callback await(state, Crucible.Machine.t(), timeout) ::
              {:ok, Crucible.Machine.t(), state} | {:error, term()}
  @callback shutdown(state, Crucible.Machine.t()) :: :ok | {:error, term()}
  @callback describe(state, Crucible.Machine.t()) :: {:ok, map()} | {:error, term()}
end

defmodule Crucible.Machine do
  defstruct [:id, :driver, :ip, :ipv6, :node, :meta]
end
```

`Crucible.FLAME.Backend`:

1. `init/1` — pick driver from `:driver` / `CRUCIBLE_DRIVER`
2. `remote_boot/1` — `boot` + `await` until SSH/HTTP/Iroh/dist is up;
   encode `FLAME_PARENT` into spec.env
3. `remote_spawn_monitor/2` — `Node.spawn_monitor` once connected
4. `system_shutdown/0` — `shutdown` the machine

Join is **not** the driver’s job. After IP is known:

- classic: `Node.connect(:"app@ip")` (cookie + EPMD or `inet_dist`)
- Iroh: runner reads `IROH_BOOTSTRAP_TICKET`
- Zenoh: runner client-connects `ZENOH_CONNECT`

## Unified spec (map every cloud)

| Crucible | Fly | K8s | EC2 | Hetzner | DO |
|---|---|---|---|---|---|
| `image` | `FLY_IMAGE_REF` | pod image | AMI or S3 bundle | image id | snapshot/image |
| `size` | cpus + memory_mb | resources | instance type | CX22 / CPX | s-1vcpu-1gb |
| `region` | Fly region | nodeSelector / zone | AWS region + subnet | NBG1 / ASH | nyc3 |
| `env` | machine env | container env | user-data | cloud-init | user_data |
| `tags` | metadata | labels | tags | labels | tags |

Drivers may ignore unknown keys. Required keys are documented per driver.

## HTTP pattern (copy FlyBackend)

All non-wrap drivers use **`Crucible.HTTP`** (Gale if present, else Req):

```elixir
Crucible.HTTP.post(url,
  auth: {:bearer, token},
  json: body,
  receive_timeout: boot_timeout)
```

Gale is the public client. Cloud APIs are H1/H2 JSON — Gale still uses
Req/Finch for that path. Do not force HTTP/3 on provisioner calls.

No Terraform. No Python Libcloud NIF. Token from env:

| Driver | Token |
|---|---|
| Fly | `FLY_API_TOKEN` |
| Hetzner | `HCLOUD_TOKEN` |
| DO | `DIGITALOCEAN_TOKEN` |
| GCP | ADC / `GOOGLE_APPLICATION_CREDENTIALS` |
| Azure | service principal |
| Render / Railway | platform API token |
| Nomad | `NOMAD_TOKEN` |
| ECS | instance/task role |

## Driver priority (implementation order)

1. **Local** — current Task loop; tests
2. **Docker** — `docker run`; CI
3. **Fly wrap** — delegate, inject overlay env
4. **K8s wrap** — same
5. **Hetzner** — cheap VMs, clean REST, `libcluster_hcloud` already exists for join
6. **DigitalOcean** — Droplet create; similar REST
7. **EC2 wrap** — FlameEC2; later native RunInstances if we want AMI+user-data without S3
8. **GCP / Azure** — larger APIs; ship later
9. **Nomad / ECS** — job/task, not VMs; same behaviour
10. **Gigalixir / Render / Railway** — PaaS; only if their API can spawn an extra replica with env

PaaS that can only “git push scale 2” is a **poor** FLAME fit (slow,
shared release, no per-call machine). Prefer Machines/Droplets/pods.

## What “all clouds” does **not** mean

- One Mix lock with every SDK
- Terraform state
- Kind as the story
- Iroh/Zenoh creating the VM

It means: **one behaviour**, optional drivers, same FLAME pool config.

## Use from Ingot / Zeiroh

```elixir
{FLAME.Pool,
 name: MyApp.Runners,
 backend: {Crucible.FLAME.Backend,
   driver: :hetzner,          # :local | :docker | :fly | :k8s | :ec2 | ...
   overlay: :iroh,            # passed through to Ingot if loaded
   image: "...",
   size: "cpx21",
   region: "nbg1"}}
```

Until Crucible is published, Ingot keeps `provisioner: :local | :fly | :k8s | :docker | :ec2` as a shim that will call Crucible when `Code.ensure_loaded?(Crucible)`.

## Tests

- Driver contract tests with a fake HTTP adapter (no live cloud)
- Local + Docker (Docker skipped if no daemon)
- Optional `:live` tags for Hetzner/Fly if tokens in env

## Name

**crucible** — melts every metal into one pour. Fits gale / ingot / dusk.
If Hex `crucible` is taken, **bloomery** or **hearth**.
