defmodule Crucible.Driver.Dummy do
  @moduledoc """
  Libcloud `DummyNodeDriver`: in-memory nodes, no HTTP, no Task loop.

  Use for contract tests. FLAME in-process spawn is `Crucible.Driver.Local`.
  """
  @behaviour Crucible.Driver

  alias Crucible.Machine

  @impl true
  def init(_opts), do: {:ok, %{seq: 0, nodes: %{}}}

  @impl true
  def boot(state, spec) do
    n = state.seq + 1
    id = "dummy-#{n}"

    machine = %Machine{
      id: id,
      name: Map.get(spec, :name, id),
      driver: :dummy,
      ip: "127.0.0.#{min(n + 1, 254)}",
      state: :running,
      extra: Map.get(spec, :extra, %{})
    }

    {:ok, machine, %{state | seq: n, nodes: Map.put(state.nodes, id, machine)}}
  end

  @impl true
  def await(state, machine, _timeout) do
    {:ok, %{machine | state: :running}, state}
  end

  @impl true
  def shutdown(_state, %Machine{}), do: :ok

  @impl true
  def describe(state, %Machine{id: id} = machine) do
    {:ok, Map.from_struct(Map.get(state.nodes, id, machine))}
  end

  def list_sizes(_state) do
    {:ok,
     [
       %Crucible.Size{id: "tiny", ram: 1024, cpu: 1, disk: 10},
       %Crucible.Size{id: "small", ram: 2048, cpu: 2, disk: 20}
     ]}
  end
end
