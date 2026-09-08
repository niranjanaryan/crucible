#!/usr/bin/env bash
set -euo pipefail

# Demo script for Crucible forum post / screencast.
# Uses the dummy driver — no cloud credentials required.

echo "=== Crucible demo ==="

echo "-- listing drivers --"
mix run -e 'IO.inspect(Crucible.drivers())'

echo "-- booting dummy VM --"
mix run -e '
  {:ok, s} = Crucible.init(driver: :dummy)
  {:ok, m, s} = Crucible.boot(s, %{name: "demo-1"})
  IO.inspect(m, label: "machine")
  {:ok, m2, s} = Crucible.await(s, m, 5000)
  IO.inspect(m2, label: "awaited")
  :ok = Crucible.shutdown(s, m2)
  IO.puts("shutdown ok")
'

echo "-- CLI smoke test --"
elixirc -o . -pa _build/dev/lib/crucible/ebin lib/crucible/cli.ex 2>/dev/null || true

echo "=== demo complete ==="
