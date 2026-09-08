# Crucible Stacks Grant — Submission Checklist

**Portal:** https://portal.stacksendowment.co/apply/current  
**Deadline:** September 23, 2026  
**Track:** Getting Started Grant  
**Theme:** Distribution & Integrations  

---

## Before You Submit

- [ ] Create/sign in to portal account
- [ ] Have GitHub URLs ready
- [ ] Have hex.pm URL ready
- [ ] Copy-paste text below into form fields

---

## Form Fields

### Project Name
```
Crucible — Stacks Multi-Cloud Node Provisioner
```

### Track
```
Getting Started Grant
```

### Theme
```
Distribution & Integrations
```

### Problem Statement
```
Stacks node deployment is fragmented: cloud console UI is manual and error-prone, Terraform requires state files and minutes to converge, Ansible is one-off and hard to version, and single-cloud CLIs lock teams into one provider. For PoX-5 Stackers and sBTC relay operators, node uptime and geographic distribution matter, but there is no unified, language-native tool that treats Stacks infrastructure as a first-class driver.
```

### Solution
```
Crucible adds a :stacks driver that provisions Stacks signer nodes, API nodes, and sBTC relay infrastructure across AWS, Hetzner, DigitalOcean, Vultr, Linode, Civo, and Scaleway from a single CLI and library API. It uses cloud-init for first-boot configuration, provides a standard boot/await/shutdown lifecycle, and works with existing Stacks tooling via standard REST and SSH.
```

### What You Will Ship
```
Milestone 1 (Week 3): :stacks signer-node driver for Hetzner, DO, AWS with cloud-init templates for stacks-node install and PoX-5 config
Milestone 2 (Week 7): API-node support with health checks + Vultr, Linode, Civo, Scaleway providers
Milestone 3 (Week 10): sBTC relay templates + Burrito binary packaging + performance benchmarks
```

### How This Helps Stacks
```
Lowers the barrier to running distributed Stacks infrastructure, enabling geographic redundancy for PoX-5 Stackers and sBTC relay operators without vendor lock-in. Makes Stacks node deployment accessible to teams already using multi-cloud tooling.
```

### Budget
```
$7,500 STX — development (6,000 STX), cloud testing infrastructure (500 STX), security review (500 STX), documentation and demos (250 STX), buffer (250 STX)
```

### Team
```
Solo builder with 6+ open-source Elixir projects, including Crucible (multi-cloud provisioner, published on Hex.pm), Gale (HTTP/3), Zeiroh (FLAME overlay), IngotCluster (Iroh+Zenoh), and Orian (S3/S5 transfer). All projects are MIT-licensed with CI, docs, and community funding.
```

---

## Links to Paste

**GitHub Repo:**
```
https://github.com/niranjanaryan/crucible
```

**Hex.pm Package:**
```
https://hex.pm/packages/crucible
```

**Documentation:**
```
https://hexdocs.pm/crucible
```

**Grant Proposal (optional if upload allowed):**
```
https://github.com/niranjanaryan/crucible/blob/main/STACKS_GRANT.md
```

---

## Milestones to Enter

### Milestone 1
- **Title:** Stacks Driver Core
- **Amount:** $2,500 STX
- **Duration:** Weeks 1–3
- **Deliverables:** 
  - Crucible.Driver.Stacks implementing init/boot/await/shutdown/describe
  - Cloud-init templates for Ubuntu 24.04 with stacks-node install and PoX-5 config
  - Support for Hetzner, DigitalOcean, AWS
  - CLI commands: crucible boot --driver stacks --kind signer
  - Tests with mocked HTTP

### Milestone 2
- **Title:** API Node + Health Monitoring
- **Amount:** $2,500 STX
- **Duration:** Weeks 4–7
- **Deliverables:**
  - :kind :api support with chain sync configuration
  - Health checks for /v2/info, /v2/chain_info, peer count
  - Vultr, Linode, Civo, Scaleway provider support
  - Integration guide: "Deploying a Stacks API node on Hetzner with Crucible"

### Milestone 3
- **Title:** sBTC Relay Support + Production Hardening
- **Amount:** $2,500 STX
- **Duration:** Weeks 8–10
- **Deliverables:**
  - :kind :sbtc_relay support with Bitcoin + Stacks networking config
  - Burrito single-binary build for standalone CLI
  - Security audit of credential handling
  - Performance benchmarks: boot-to-healthy time across providers

---

## Disbursement Schedule
```
50% upfront (Milestone 1, Week 3)
50% upon completion (Milestone 3, Week 10)
```

---

## After Submission

1. Save confirmation number/email
2. Monitor inbox for grant program manager follow-up
3. Respond within 12 hours if reviewers ask for clarification
4. Prepare KYC/KYB docs (only requested after approval)
