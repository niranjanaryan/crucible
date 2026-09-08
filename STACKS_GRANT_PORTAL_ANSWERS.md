# Crucible — Stacks Grant Portal Answers

**Cycle:** Q3 2026  
**Deadline:** September 23, 2026  
**Portal:** https://portal.stacksendowment.co/apply/cycle-3  

---

## Section 01 — Applicant Identity
**Status:** Already complete in portal  
- Applicant: Individual · Niranjan A
- Contact: Niranjan Anand
- Jurisdiction: INDIA

---

## Section 02 — Project

### Project Name
```
Crucible — Stacks Multi-Cloud Node Provisioner
```

### Website or Repo (optional)
```
https://github.com/niranjanaryan/crucible
```

### Primary Category
```
Developer Tools & Infrastructure
```

### Secondary Category
```
Developer Tools & Infrastructure - Infrastructure
```

### Project Description
```
Crucible is a multi-cloud provisioner for the Elixir ecosystem. It already boots VMs across AWS, Hetzner, DigitalOcean, Vultr, Linode, Civo, and Scaleway using a single CLI and library API. This grant funds a first-class Stacks driver that provisions Stacks signer nodes, API nodes, and sBTC relay infrastructure from the same tool. Instead of manual cloud console work, Terraform scripts, or one-off Ansible playbooks, operators will run one command to deploy a Stacks node on any major cloud, with cloud-init handling first-boot configuration and Crucible managing the full lifecycle: boot, await, shutdown.
```

---

## Section 03 — Audience and Ecosystem Fit

### Primary Audience
```
Stacks node operators, PoX-5 Stackers, sBTC relay operators, and DevOps teams who need to deploy and manage Stacks infrastructure across multiple cloud providers.
```

### Audience Segmentation
```
1. PoX-5 Stackers running signer nodes in multiple regions for redundancy
2. sBTC relay operators needing scalable, reproducible relay infrastructure
3. dApp backends requiring local Stacks API nodes for testing and development
4. DevOps teams managing Stacks infrastructure at scale across AWS, Hetzner, DO, and other providers
```

### Why Stacks?
```
The Nakamoto upgrade, PoX-5, and sBTC launch have created immediate demand for distributed Stacks node infrastructure. Stacks node deployment today is fragmented: manual cloud console work, Terraform state files, Ansible scripts, and single-cloud CLIs. There is no unified, language-native tool that treats Stacks as a first-class driver. Crucible fills this gap by providing a standard boot/await/shutdown lifecycle with cloud-init for immutable first-boot configuration. This matters because node uptime and geographic distribution are critical for PoX-5 Stackers and sBTC relay operators, and the existing tooling forces teams to maintain N separate scripts for N clouds.
```

### Maintenance Plan
```
Crucible is MIT-licensed and maintained as part of a broader Elixir infrastructure toolkit (Gale, Zeiroh, IngotCluster, Orian). The Stacks driver will receive bug fixes and cloud updates as part of ongoing maintenance. Issues are tracked on GitHub with labeled milestones. Community contributions are welcome and will be guided by issue templates and a CONTRIBUTING.md. After the grant, the driver will support Nakamoto-era node configs and evolve with Stacks releases. No exit strategy — this is core infrastructure.
```

### Ecosystem Fit
```
This project directly supports the Q3 2026 "Distribution & Integrations" theme. Crucible makes it easier for products and operators to integrate with and expand the Stacks ecosystem by removing the infrastructure barrier to running Stacks nodes. It enables geographic redundancy for PoX-5 Stackers, simplifies sBTC relay operator infrastructure, and makes Stacks node deployment accessible to teams already using multi-cloud tooling. The result is more resilient, widely distributed Stacks infrastructure that can support growing network demand.
```

---

## Section 04 — Risk and Prior History

### Prior Grant History
```
No prior Stacks grants. First application.
```

### Prior Projects / Track Record
```
Active maintainer of 6+ open-source Elixir repos with CI, docs, and community funding:
- Crucible (multi-cloud provisioner, published on Hex.pm v0.1.1)
- Gale (HTTP/3 Phoenix adapter, published on Hex.pm)
- Zeiroh (Phoenix FLAME overlay for Iroh/Zenoh, published on Hex.pm)
- IngotCluster (Iroh+Zenoh cluster, published on Hex.pm)
- Orian (S3/S5 transfer, published on Hex.pm)
- Dusk (Zenoh-first cluster, published on Hex.pm)

All projects are MIT-licensed with GitHub Actions CI, hex docs, and community funding pages.
```

### Key Risks
```
1. Stacks node config changes between releases — Mitigation: pin to stable stacks-node Docker image; document version in cloud-init
2. Cloud provider API changes — Mitigation: driver layer abstracts HTTP; only cloud-init templates need updates
3. Scope creep (too many clouds) — Mitigation: Milestone 1 limits to 3 providers; Milestone 2 adds 4 more
4. Insufficient testing without live Stacks node — Mitigation: use mocked RPC responses for unit tests; live tests only for health checks
5. Solo builder bandwidth — Mitigation: scope is intentionally small (10 weeks, 3 milestones); can defer advanced features
```

---

## Section 05 — Track and Qualification
**Status:** Already complete in portal  
- Track: Getting Started
- Requested: $7,500 STX
- Qualification: Open track, no gates

---

## Section 06 — Track-Specific Context

### What are you proposing to explore or build?
```
A Stacks driver for Crucible that provisions Stacks signer nodes, API nodes, and sBTC relay infrastructure across AWS, Hetzner, DigitalOcean, Vultr, Linode, Civo, and Scaleway from a single CLI and library API. The driver uses cloud-init for first-boot configuration, provides a standard boot/await/shutdown lifecycle, and works with existing Stacks tooling via standard REST and SSH.
```

### What user or ecosystem problem motivates the project?
```
Stacks node deployment is fragmented. Operators use manual cloud console work, Terraform scripts, Ansible playbooks, or single-cloud CLIs. For PoX-5 Stackers and sBTC relay operators, node uptime and geographic distribution matter, but there is no unified tool that treats Stacks as a first-class driver. This forces teams to maintain N separate scripts for N clouds, increasing operational burden and reducing agility.
```

### Why is Stacks the right environment for this work?
```
Stacks is experiencing rapid growth in node infrastructure demand due to PoX-5, sBTC, and the Nakamoto upgrade. The ecosystem needs repeatable, auditable ways to deploy nodes across regions and providers. Crucible's Libcloud-shaped behaviour is a natural fit for Stacks' growing infrastructure needs. The project aligns with Stacks' mission of Bitcoin-native finance by making node deployment accessible to cloud-native teams.
```

### What have you already validated, prototyped, or learned?
```
Crucible is already published on Hex.pm (v0.1.1) with 25 passing tests, CI matrix builds, and full documentation. It has a working driver framework with Hetzner, Fly, K8s, EC2, and 100+ provider catalog. The Libcloud-shaped behaviour is proven. The Stacks driver is a natural extension of this existing framework, requiring only Stacks-specific cloud-init templates and provider configuration. No fundamental architectural changes are needed.
```

### Who will do the work and what experience do they bring?
```
Niranjan Aryan — solo builder with 6+ open-source Elixir projects. Built Crucible (multi-cloud provisioner), Gale (HTTP/3), Zeiroh (FLAME overlay), IngotCluster (Iroh+Zenoh), Orian (S3/S5 transfer), and Dusk (Zenoh cluster). All published on Hex.pm with CI, docs, and community funding. Deep expertise in Elixir, distributed systems, P2P networking, and cloud infrastructure.
```

### What is the smallest useful outcome this grant should produce?
```
A working `:stacks` driver that provisions Stacks signer nodes on at least 3 cloud providers (Hetzner, DigitalOcean, AWS) with cloud-init configuration. This gives operators an immediate, practical way to deploy Stacks nodes without manual console work or Terraform scripts.
```

### What evidence will show the concept is worth continuing?
```
1. Published Hex package `{:crucible_stacks, "~> 0.1"}` with working driver tests
2. Successful deployment of a Stacks signer node on 3+ clouds using Crucible
3. Community feedback from Stacks node operators
4. Integration with existing Stacks tooling (stacks-node, sBTC relay software)
5. Adoption metrics: GitHub stars, Hex downloads, community contributions
```

### What dependencies or risks could affect delivery?
```
1. Stacks node config format changes — pinned to stable Docker image
2. Cloud provider API changes — abstracted at driver layer
3. NAT traversal for node discovery — using cloud-init with public IPs
4. Solo builder bandwidth — scope is intentionally small with deferrable advanced features
```

### What support from the Stacks ecosystem would help?
```
1. Feedback from Stacks node operators on cloud-init templates
2. Early testing of signer/API node deployments on various clouds
3. Documentation of Stacks-specific networking requirements
4. Community promotion of the driver to Stackers and relay operators
```

### How will you share progress or learnings publicly?
```
1. Weekly GitHub commits with public progress
2. Monthly blog posts or forum updates on Stacks forum
3. Screencasts showing node deployment across clouds
4. Open issues for community feedback
5. Published Hex package with full documentation
6. Stacks community event demo at completion
```

### What happens after the grant if the work succeeds?
```
The Stacks driver becomes a permanent part of Crucible, maintained as part of the broader Elixir infrastructure toolkit. It will receive bug fixes, cloud updates, and new Stacks features as part of ongoing maintenance. The driver will support Nakamoto-era node configs and evolve with Stacks releases. Community contributions will be welcomed via labeled issues. No exit strategy — this is core infrastructure for Stacks operators.
```

### Any other context reviewers should consider?
```
Crucible already has a production-ready multi-cloud provisioning framework. The Stacks driver is not a research project — it's an extension of proven code. The 10-week timeline is realistic because the driver behaviour, HTTP layer, and CLI are already implemented. The grant focuses on Stacks-specific templates and testing, not foundational infrastructure. This is a low-risk, high-impact project that directly addresses a clear gap in the Stacks ecosystem.
```

---

## Section 07 — Compliance Readiness

### Individual Applicant Readiness
```
I have reviewed the Vouched ID requirements and will be able to complete the required KYC through Vouched if selected.
```

---

## Section 08 — Milestones

### Milestone 1
- **Name:** Stacks Driver Core
- **Target date:** 4 weeks from project start
- **Description:** Working :stacks driver with signer-node support for Hetzner, DigitalOcean, and AWS. Includes Crucible.Driver.Stacks implementation, cloud-init templates for Ubuntu 24.04 with stacks-node install and PoX-5 config, CLI commands, and tests with mocked HTTP.
- **Success criteria:** Published Hex package {:crucible_stacks, "~> 0.1"} with docs and working demo showing signer node deployment on 3 clouds
- **Payment percent:** 20
- **Amount:** 1,500 STX

### Milestone 2
- **Name:** API Node + Health Monitoring
- **Target date:** 8 weeks from project start
- **Description:** API node support with health checks and multi-cloud expansion. Includes :kind :api support, health checks for /v2/info and /v2/chain_info, Vultr/Linode/Civo/Scaleway provider support, and integration guide.
- **Success criteria:** Published v0.2.0 with docs and screencast showing signer + API node deployment across two clouds
- **Payment percent:** 30
- **Amount:** 2,250 STX

### Milestone 3 (Final)
- **Name:** sBTC Relay Support + Production Hardening
- **Target date:** 10 weeks from project start
- **Description:** sBTC relay node templates and production-ready packaging. Includes :kind :sbtc_relay support, Burrito single-binary build, security audit of credential handling, and performance benchmarks.
- **Success criteria:** Published v0.3.0, demo at Stacks community event or forum post, and open issues for community feedback
- **Payment percent:** 50
- **Amount:** 3,750 STX
- **Final adoption metric:** Hex downloads of {:crucible_stacks, "~> 0.1"} — measured via hex.pm download counter. Target: 100+ downloads within 30 days of publication.

---

## Quick Copy-Paste Summary

**Project name:** Crucible — Stacks Multi-Cloud Node Provisioner

**Problem:** Stacks node deployment is fragmented across manual console work, Terraform scripts, Ansible, and single-cloud CLIs. No unified tool treats Stacks as a first-class driver.

**Solution:** A Stacks driver for Crucible that provisions signer/API/sBTC relay nodes across 7+ clouds from one CLI/library API with standard lifecycle management.

**What you will ship:**
- Week 4: :stacks signer-node driver for Hetzner/DO/AWS
- Week 8: API-node support + Vultr/Linode/Civo/Scaleway
- Week 10: sBTC relay templates + Burrito binary + benchmarks

**Budget:** $7,500 STX — development, testing infra, security review, docs

**Team:** Solo builder, 6+ open-source Elixir projects, Crucible 0.1.1 on Hex.pm
