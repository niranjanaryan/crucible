# Apache Libcloud → Crucible

Python library: [libcloud.apache.org](https://libcloud.apache.org/)
Compute API: [NodeDriver](https://libcloud.apache.org/docs/compute/api.html)
Version surveyed: 3.8 / 3.9 docs.

Libcloud is **not** an Elixir package and **not** a NIF we should bind.
Crucible copies its **compute object model**, not the Python runtime.

## What Libcloud is

One Python API over many vendor HTTP APIs. Six *kinds* of driver
(compute, storage, DNS, load balancer, container, backup). FLAME only
needs **compute** (create a box, wait until it has an IP, destroy it).

Factory:

```python
from libcloud.compute.types import Provider
from libcloud.compute.providers import get_driver

Driver = get_driver(Provider.EC2)
driver = Driver(key, secret, region="us-east-1")
node = driver.create_node(name="n1", size=sizes[0], image=images[0])
driver.wait_until_running([node])
driver.destroy_node(node)
```

Drivers are **lazy-loaded** from a `DRIVERS` dict (`providers.py`).
Each class sets `connectionCls` (HTTP + auth headers) and maps JSON
to `Node`.

## Compute types (copy these)

| Libcloud | Meaning | Crucible |
|---|---|---|
| `Node` | Instance: id, name, state, public_ips, private_ips, extra | `Crucible.Machine` (+ `state`) |
| `NodeSize` | Flavor (ram, cpu, disk, price) | `Crucible.Size` |
| `NodeImage` | AMI / snapshot / OS image | `Crucible.Image` |
| `NodeLocation` | Region / AZ | `Crucible.Location` |
| `NodeState` | RUNNING, PENDING, STARTING, STOPPED, TERMINATED, ERROR, … | `Crucible.NodeState` |
| `KeyPair` | SSH key | skip for FLAME (cookie + Iroh, not SSH) |
| `features["create_node"]` | `:ssh_key`, `:password`, `:generates_password` | `features[:boot]` e.g. `:env`, `:user_data` |

`Node` is a dumb struct. **The driver** talks to the cloud. `node.destroy()`
is `driver.destroy_node(node)`.

## NodeDriver methods (what FLAME actually uses)

Must have:

- `create_node(name, size, image, location=None, auth=None)` → `Node`
- `destroy_node(node)` → bool
- `wait_until_running(nodes)` — poll until RUNNING + IP
- `list_nodes` / `list_images` / `list_sizes` / `list_locations`

Useful later:

- `start_node` / `stop_node` / `reboot_node`
- `create_key_pair` — only if we SSH for debug

**Do not copy `deploy_node`.** That SSHs in and runs `ScriptDeployment`.
FLAME injects `FLAME_PARENT` via **env / cloud-init** and the release
starts `FLAME.Terminator`. Iroh/Zenoh join after boot. SSH is a
fallback for broken images, not the happy path.

Vendor extras stay as `ex_*` in Python (`ex_userdata`, `ex_keyname`).
In Elixir: `spec.extra` map, never flatten every Hetzner field onto
the behaviour.

## Dummy driver (tests)

`DummyNodeDriver` always succeeds, hands out `127.0.0.x`, no HTTP.
Crucible equivalent: `Crucible.Driver.Dummy` (in-memory node list).
Keep `Local` for real in-process FLAME spawn; Dummy is for **contract
tests** of list/create/destroy without a Task loop.

## Provider matrix vs our needs

Libcloud compute **has**: EC2, GCE, Azure ARM, DigitalOcean, Linode,
Vultr, Equinix Metal (Packet), OpenStack, CloudStack, Aliyun ECS,
OVH, kubevirt, Libvirt, …

Libcloud compute **does not have** (or not as NodeDriver):

- **Fly Machines** — FLAME already wraps this; wrap, don’t invent
- **Hetzner Cloud** — no first-class driver; we write `crucible_hetzner`
- **Railway / Render / Gigalixir** — PaaS, not VMs
- **Nomad / ECS** — jobs, not `create_node` VMs (separate driver kind)

K8s in Libcloud is mostly **`container.drivers.kubernetes`**
(namespaces, deploy_container), plus kubevirt as compute. For Phoenix
we wrap **`FLAMEK8sBackend`**, not Libcloud’s container API.

## HTTP layer

Libcloud: `connectionCls` + `add_default_headers` + JSON body.
Crucible: **`Crucible.HTTP`** → Gale (preferred) or Req. Same idea as
`connectionCls`. Control-plane calls stay H1/H2.

Do **not** call Python Libcloud via Port/PyErr. Dual runtime, GPL-adjacent
ops pain, and FLAME boot budget is seconds.

## Mapping to Crucible.Driver

| Libcloud | Crucible |
|---|---|
| `get_driver(Provider.X)` | `Crucible.Driver.resolve(driver: :hetzner)` |
| `Driver(key, secret, region=)` | `init(token:, region:)` |
| `create_node` | `boot(state, spec)` |
| `wait_until_running` | `await(state, machine, timeout)` |
| `destroy_node` | `shutdown(state, machine)` |
| `list_nodes` + extra | `describe` now; `list/3` later |
| `DummyNodeDriver` | `Crucible.Driver.Dummy` |
| `deploy_node` (SSH) | **omit** |

## Takeaway

Libcloud’s value is **Node + Size + Image + Location + State** and a
**per-vendor HTTP driver**, not 80 half-maintained providers. Crucible
implements that subset, wraps existing Elixir FLAME backends for Fly /
K8s / EC2, and adds Hetzner/DO as first-class Req drivers. Overlay
(Iroh/Zenoh) stays outside the driver.
