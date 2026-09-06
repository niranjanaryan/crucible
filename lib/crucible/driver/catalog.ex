defmodule Crucible.Driver.Catalog do
  @moduledoc """
  Named cloud with no codec yet. `boot` returns `{:error, {:not_implemented, name}}`.
  """
  @behaviour Crucible.Driver

  @impl true
  def init(opts) do
    {:ok, %{provider: Keyword.fetch!(opts, :provider), meta: Keyword.get(opts, :meta, %{})}}
  end

  @impl true
  def boot(state, _spec), do: {:error, {:not_implemented, state.provider, state.meta}}

  @impl true
  def await(state, machine, _), do: {:ok, machine, state}

  @impl true
  def shutdown(state, _), do: {:error, {:not_implemented, state.provider, state.meta}}

  @impl true
  def describe(state, machine),
    do: {:ok, Map.merge(Map.from_struct(machine), %{provider: state.provider})}
end
