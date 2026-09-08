# Crucible Launch Plan — Elixir Forum & Community

## Objectives

1. Announce Crucible on the Elixir Forum with clear positioning.
2. Drive awareness among Phoenix/FLAME and multi-cloud users.
3. Convert early users into sponsors and contributors.

## Target Audiences

- Phoenix FLAME / Zeiroh adopters.
- Multi-cloud DevOps using AWS, Hetzner, GCP, Azure.
- OTP / CLI tooling enthusiasts in the Elixir community.

## Messaging

Crucible is the **multi-cloud provisioner** for the Elixir stack:
it boots and removes VMs across clouds, matching the CLI shape of
**orian**, with a library API for Phoenix FLAME.

Key hooks:
- `crucible boot --driver dummy --name n1`
- Single Burrito binary + escript fallback.
- `~/.config/crucible/config.yaml` + `.env` credential flow.
- Erlang/OTP native, no Mix runtime dependency.

## Phased Rollout

### Phase 1 — Pre-launch (this week)

- [x] Add FUNDING section to README.
- [ ] Polish hex.pm metadata (`mix.exs`: description, keywords, links).
- [ ] Write a reproducible demo GIF/screencast for the forum post.
- [ ] Prepare a 12–16 sentence announcement draft for Elixir Forum.

### Phase 2 — Forum Announcement

Post title: **"Crucible: boot VMs across AWS/Hetzner/GCP/Azure from Elixir (Phoenix FLAME ready)"**

Body outline:
1. What it is and why it exists.
2. One-liner install: `mix crucible.install`.
3. Demo snippet showing `crucible boot`, `await`, `shutdown`.
4. Burrito single-binary note.
5. Funding / sponsorship ask.
6. Link to hex.pm, GitHub, hexdocs.

Channels:
- [Elixir Forum — Projects](https://elixirforum.com/c/projects/6)
- [Elixir Forum — Announcements](https://elixirforum.com/c/announcements/14)
- [Elixir Forum — Phoenix](https://elixirforum.com/c/phoenix-framework/5) *(FLAME angle)*

### Phase 3 — Follow-up (days 1–7)

- Respond to every question within 12 hours.
- Publish a short blog-style post or thread with a real-world FLAME scenario.
- Share on Twitter/X with a code snippet GIF.
- Publish release notes to the `#releases` channel if Slack/Discord exists.

### Phase 4 — Sustain (weeks 2–4)

- Publish a tutorial: "Deploying a Phoenix FLAME app with Crucible + Zeiroh".
- Add more drivers (libcloud backend contributions welcome).
- Monitor hex.pm downloads and GitHub stars weekly.

## Sponsorship Links to Add

| Platform | URL |
|----------|-----|
| GitHub Sponsors | https://github.com/sponsors/niranjanaryan |
| Patreon | https://patreon.com/niranjanaryan |
| Ko-fi | https://ko-fi.com/niranjanaryan |
| Buy Me a Coffee | https://www.buymeacoffee.com/niranjanaryan |

## Success Metrics

- 100+ hex.pm downloads in first 7 days.
- 3+ forum replies generating discussion.
- 1 community-contributed driver or issue.

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Low initial traction | Post FLAME-specific angle in Phoenix subforum |
| Questions about credentials/security | Document env/.env/crucible.yaml clearly; add SECURITY.md note |
| Funding perceived as premature | Frame as "if this is useful, consider sponsoring" |
