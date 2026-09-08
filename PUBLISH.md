# Publish Crucible to Hex.pm and GitHub

Canonical git remote: `https://github.com/niranjanaryan/crucible`

1. `mix test`
2. Version in `mix.exs` + `CHANGELOG.md`
3. `mix hex.build`
4. `HEX_PUBLISH=1 mix hex.publish`
5. `git tag v0.1.0 && git push origin v0.1.0`
