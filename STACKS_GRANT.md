# Stacks Endowment Grant Application — Crucible Stacks Infrastructure

**Track:** Getting Started Grant  
**Theme:** Distribution & Integrations (Q3 2026)  
**Request:** $7,500 STX  
**Timeline:** 10 weeks  

---

## 1. Project Summary

**Crucible** is a multi-cloud provisioner for the Elixir ecosystem. We are requesting a Getting Started Grant to add a first-class **Stacks driver** that can boot, configure, and manage Stacks signer nodes, API nodes, and sBTC relay infrastructure across AWS, Hetzner, DigitalOcean, Vultr, Linode, Civo, Scaleway, and other clouds from a single CLI and library API.

Today, deploying a Stacks node requires manual cloud console work, Terraform scripts, or one-off Ansible playbooks. There is no unified, language-native tool that treats Stacks infrastructure as a first-class driver alongside existing clouds. Crucible fills this gap: one behaviour (`boot`, `await`, `shutdown`, `describe`), many clouds, zero lock-in.

**Why Stacks:** The Nakamoto upgrade, PoX-5, and sBTC launch have increased demand for distributed Stacks node infrastructure. Stackers, sBTC relay operators, and dApp backends all need repeatable, auditable ways to deploy nodes across regions and providers. Crucible makes that accessible to Elixir, Rust, and Python teams alike.

---

## 2. Problem Statement

Stacks node deployment is fragmented:

- **Cloud console UI**: manual, error-prone, not reproducible.
- **Terraform / Pulumi**: slow (minutes per run), state-file lock-in, not idiomatic for runtime provisioning.
- **Ansible / shell scripts**: one-off, hard to version, no standard lifecycle (`boot` → `await` → `shutdown`).
- **Single-cloud CLIs**: lock you into one provider; multi-cloud requires maintaining N scripts.

For sBTC relay operators and PoX-5 Stackers specifically, node uptime and geographic distribution matter. Teams need to spin up nodes in specific regions, monitor them, and tear them down — without rewriting infrastructure code per cloud.

**The gap:** No multi-cloud provisioner treats Stacks as a first-class driver. Existing options are either generic IaC tools or single-cloud CLIs.

---

## 3. Solution

Crucible adds a `:stacks` driver that supports:

1. **Signer nodes** — boot a Stacks signer VM with the correct `stacks-node` config, key material injection, and PoX-5 voting settings.
2. **API / RPC nodes** — boot a Stacks API node with chain data sync, peer discovery, and health-check endpoints.
3. **sBTC relay infrastructure** — boot relay containers/VMs pre-configured for Bitcoin and Stacks connectivity.

The driver uses the same `Crucible.Driver` behaviour as all other clouds:

```elixir
{:ok, state} = Crucible.init(driver: :stacks, provider: :hetzner, region: :nbg1)
{:ok, machine, state} = Crucible.boot(state, %{
  kind: :signer,
  image: "ubuntu-24.04",
  size: "cpx21",
  env: %{
    "STACKS_PRIVATE_KEY" => "...",
    "STACKS_POX_V1" => "..."
  }
})
{:ok, machine, state} = Crucible.await(state, machine)
:ok = Crucible.shutdown(state, machine)
```

CLI parity:

```bash
crucible boot --driver stacks --kind signer --region nbg1
crucible sizes --driver stacks
crucible rm --driver stacks --id stacks-signer-1
```

**Design choices:**
- Cloud-init / user-data for first-boot configuration (no SSH post-configuration required).
- Driver is optional: `{:crucible, "~> 0.1"}` pulls only the core; `{:crucible, "~> 0.1", extras: [:stacks]}` pulls the Stacks driver.
- No Mix runtime dependency for the standalone CLI.
- Works with existing Elixir, Rust, and Python Stacks tooling via standard REST and SSH.

---

## 4. Why This Matters for Stacks

**Ecosystem impact:**
- Lowers the barrier to running Stacks infrastructure. A developer can go from zero to a running signer node in one command.
- Enables geographic redundancy for PoX-5 Stackers and sBTC relay operators without vendor lock-in.
- Makes Stacks node deployment accessible to teams already using Crucible for other clouds (Fly, Hetzner, DO, etc.).

**Strategic alignment:**
- Directly supports the Nakamoto-upgraded network by making node deployment repeatable and auditable.
- Enables sBTC utility by simplifying relay operator infrastructure.
- Fits the Q3 2026 "Distribution & Integrations" theme: infrastructure that makes it easier for products and operators to integrate with and expand the Stacks ecosystem.

**Ecosystem-first:**
- The `:stacks` driver is open-source (MIT) and composable with any Stacks tooling.
- Other projects can build on top of Crucible's Stacks driver without asking permission.
- No token, no platform fee, no governance token.

---

## 5. Milestones

### Milestone 1: Stacks Driver Core (Weeks 1–3, $2,500 STX)

**Deliverable:** Working `:stacks` driver with signer-node support.

- `Crucible.Driver.Stacks` implementing `init/1`, `boot/2`, `await/3`, `shutdown/2`, `describe/2`.
- Cloud-init templates for Ubuntu 24.04 with `stacks-node` install and PoX-5 config.
- Support for `:hetzner`, `:digitalocean`, and `:aws` as underlying providers.
- CLI: `crucible boot --driver stacks --kind signer`, `crucible rm --driver stacks --id <id>`.
- Tests: driver contract tests with mocked HTTP; integration test against `:local` and `:dummy`.

**Verification:** Published Hex package `{:crucible_stacks, "~> 0.1"}` with docs and a working demo.

### Milestone 2: API Node + Health Monitoring (Weeks 4–7, $2,500 STX)

**Deliverable:** API node support with health checks and multi-cloud expansion.

- `:kind :api` support with chain sync configuration.
- Built-in health checks: `/v2/info`, `/v2/chain_info`, peer count monitoring.
- Add `:vultr`, `:linode`, `:civo`, `:scaleway` as underlying providers.
- `crucible await --driver stacks` polls health endpoints until the node is synced.
- Integration guide: "Deploying a Stacks API node on Hetzner with Crucible".

**Verification:** Published v0.2.0 with docs and a screencast showing signer + API node deployment across two clouds.

### Milestone 3: sBTC Relay Support + Production Hardening (Weeks 8–10, $2,500 STX)

**Deliverable:** sBTC relay node templates and production-ready packaging.

- `:kind :sbtc_relay` support with Bitcoin + Stacks networking config.
- Burrito single-binary build for the standalone CLI.
- Security audit of credential handling (env, `.env`, YAML) with a public `SECURITY.md`.
- Performance benchmarks: boot-to-healthy time across providers.

**Verification:** Published v0.3.0, demo at a Stacks community event or forum post, and open issues for community feedback.

---

## 6. Budget

| Item | Amount (STX) | Notes |
|------|-------------|-------|
| Development (3 milestones) | 6,000 | 10 weeks at ~600 STX/week |
| Cloud infrastructure for testing | 500 | Hetzner, DO, AWS credits for live driver tests |
| Security review | 500 | Credential handling, cloud-init templates |
| Documentation & demo production | 250 | Screencasts, guides, forum content |
| Buffer | 250 | Contingency |
| **Total** | **7,500** | Mid-range of Getting Started Grant |

**Disbursement:** 50% at Milestone 1 (Week 3), 50% at Milestone 3 (Week 10).

---

## 7. Team

**Niranjan Aryan** — solo builder, [@niranjanaryan](https://github.com/niranjanaryan).

- **Relevant experience:** Built Crucible (0.1.1, published on Hex.pm), a Libcloud-shaped multi-cloud provisioner with 100+ provider catalog, AWS SigV4 auth, Hetzner/Fly/K8s/EC2 drivers, and a standalone Burrito CLI. Previously built Gale (HTTP/3), Oriano (S3/S5 transfer CLI), Ingot (Iroh+Zenoh cluster), and Zeiroh (Phoenix FLAME overlay) — all open-source, MIT.
- **GitHub:** [github.com/niranjanaryan](https://github.com/niranjanaryan)
- **Stacks engagement:** Applying to build infrastructure that makes Stacks node deployment accessible to cloud-native teams. No prior Stacks grant history; this is a first application with a concrete, shippable plan.

---

## 8. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Stacks node config changes between releases | Medium | Medium | Pin to stable `stacks-node` Docker image; document version in cloud-init |
| Cloud provider API changes | Low | Low | Driver layer abstracts HTTP; only cloud-init templates need updates |
| Scope creep (too many clouds) | Medium | Medium | Milestone 1 limits to 3 providers; Milestone 2 adds 4 more |
| Insufficient testing without live Stacks node | Low | Medium | Use mocked RPC responses for unit tests; live tests only for health checks |
| Solo builder bandwidth | Medium | Medium | Scope is intentionally small (10 weeks, 3 milestones); can defer advanced features |

---

## 9. Ecosystem Commitment

- **Long-term maintenance:** Crucible is MIT-licensed and maintained as part of a broader Elixir infrastructure toolkit (Gale, Oriano, Ingot, Zeiroh). The Stacks driver will receive bug fixes and cloud updates as part of ongoing maintenance.
- **Community:** Open to community contributions; will tag `good first issue` for Stacks driver work.
- **Stacks alignment:** After the grant, the driver will support Nakamoto-era node configs and evolve with Stacks releases. No exit strategy — this is core infrastructure.

---

## 10. Proof of Work

- **Crucible:** Published on Hex.pm (v0.1.1), 25 passing tests, CI with matrix builds, docs on hexdocs.pm.
- **GitHub:** Active maintainer of 6+ open-source Elixir repos with CI, funding, and community docs.
- **Design docs:** `DESIGN.md` outlines the Libcloud-shaped behaviour and driver priority list — Stacks is a natural addition.

---

## 11. Application Answers (Form-Field Ready)

**Project name:** Crucible — Stacks Multi-Cloud Node Provisioner

**Track:** Getting Started Grant

**Theme:** Distribution & Integrations

**Problem (one sentence):** Deploying and managing Stacks signer, API, and sBTC relay nodes across multiple clouds requires manual work or single-cloud tools that lock teams into one provider.

**Solution (one sentence):** A Stacks driver for Crucible that provisions Stacks node infrastructure across any major cloud from a single CLI and library API.

**What you will ship and by when:**
- Week 3: `:stacks` signer-node driver for Hetzner, DO, AWS
- Week 7: API-node support + Vultr, Linode, Civo, Scaleway
- Week 10: sBTC relay templates + production packaging

**How this helps Stacks:** Lowers the barrier to running distributed Stacks infrastructure, enabling geographic redundancy for PoX-5 Stackers and sBTC relay operators without vendor lock-in.

**Budget:** $7,500 STX — development, testing infrastructure, security review, documentation.

**Team:** Solo builder with 6+ open-source Elixir projects, including a published multi-cloud provisioner (Crucible 0.1.1 on Hex.pm).
