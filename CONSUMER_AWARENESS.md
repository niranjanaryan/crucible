# Crucible Consumer Awareness

## Target Audience

| Segment | Who they are | Why they care |
|---------|-------------|---------------|
| PoX-5 Stackers | Run signer nodes across regions | One-command deployment without Terraform/Ansible |
| sBTC relay operators | Multi-region relay infrastructure | Repeatable, auditable deployments |
| DevOps/infra teams | Manage Stacks at scale | Single CLI for AWS, Hetzner, DO, Fly, K8s |
| Stacks dApp backends | Need API nodes with failover | Geographic redundancy without vendor lock-in |

## Awareness Channels

### Stacks Ecosystem
- **Stacks Forum:** "Deploying Stacks signer nodes on Hetzner with Crucible"
- **Stacks Discord:** CLI walkthrough, deployment demos
- **Stacks GitHub:** Issues, discussions, PRs

### Elixir Ecosystem
- **Elixir Forum:** "Multi-cloud provisioning in Elixir"
- **Hex.pm:** Package description, docs, changelogs
- **GitHub:** Issues, discussions, stars, forks

### Social Media
- **Twitter/X:** Deployment demos, benchmark screenshots
- **Reddit r/elixir:** Cross-post tutorials
- **LinkedIn:** Professional audience, enterprise Stacks operators

## Content Strategy

### Blog Posts / Tutorials
1. **"Deploying a Stacks Signer Node on Hetzner with Crucible"**
   - Step-by-step CLI walkthrough
   - Cloud-init config for `stacks-node`
   - Health check polling until synced
   - Target: PoX-5 Stackers

2. **"Multi-Cloud Stacks Infrastructure with Crucible"**
   - AWS, Hetzner, DO, Fly, K8s comparison
   - Cost estimation per provider/region
   - Geographic redundancy patterns
   - Target: sBTC relay operators

3. **"Crucible + Zeiroh: Provisioned FLAME Workers for Stacks"**
   - Cross-cloud worker provisioning
   - Auto-discovery via Iroh/Zenoh
   - Distributed indexer example
   - Target: dApp developers

### Demo Videos
- **5 min:** Provisioning a Stacks signer node on Hetzner
- **5 min:** Multi-cloud deployment across 3 providers

### Benchmark Publications
- `benchmark/BOOT_TIME.md` — Boot-to-healthy time across providers
- `benchmark/COST_COMPARISON.md` — Cost per region/provider

## Adoption Metrics

| Metric | Baseline | 30-day target | 90-day target |
|--------|----------|---------------|---------------|
| Hex downloads | 0 | 200+ | 1,000+ |
| GitHub stars | 0 | 50+ | 200+ |
| Stacks Forum replies | 0 | 5+ | 20+ |
| Blog post views | 0 | 500+ | 2,000+ |
| Demo video views | 0 | 200+ | 1,000+ |

## Timeline

### Week 1-2
- [ ] Publish deployment guide
- [ ] Post Stacks Forum tutorial
- [ ] Record provisioning demo

### Week 3-4
- [ ] Post Elixir Forum thread
- [ ] Submit Reddit r/elixir cross-post
- [ ] Reach out to 5 Stacks node operators

### Week 5-8
- [ ] Publish multi-cloud comparison
- [ ] Monitor and respond to feedback
- [ ] Update cost benchmarks

## Key Messages

**For Stacks operators:**
> "Deploy Stacks signer nodes, API nodes, and sBTC relays in minutes, not hours. One CLI, any cloud, zero lock-in."

**For Elixir developers:**
> "Libcloud-shaped behaviour for Elixir. Same `boot`/`await`/`shutdown` API across 7+ cloud providers. First-class Stacks driver."

## Competitive Positioning

| Competitor | Gap we fill |
|------------|-------------|
| Terraform/Pulumi | Not Elixir-native, slow convergence, state-file lock-in |
| Ansible/shell scripts | One-off, hard to version, no standard lifecycle |
| Single-cloud CLIs | Lock teams into one provider |
| Cloud vendor tools | Vendor lock-in, no multi-cloud abstraction |

**Our advantage:** Only Elixir-native multi-cloud provisioner with a first-class Stacks driver and standard lifecycle behaviour.

---

*This document is part of the Elixir Distributed Stack consumer awareness strategy.*
