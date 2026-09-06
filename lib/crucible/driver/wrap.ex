defmodule Crucible.Driver.Wrap do
  @moduledoc """
  Wraps an existing `FLAME.Backend` module (`FLAME.FlyBackend`,
  `FLAMEK8sBackend`, `FlameEC2`) as a Crucible driver.

  `init` is deferred until `FLAME.Pool` supplies `:terminator_sup`.
  """
  @behaviour Crucible.Driver

  alias Crucible.Machine

  @impl true
  def init(opts) do
    backend = Keyword.fetch!(opts, :backend)

    if Code.ensure_loaded?(backend) do
      {:ok, %{backend: backend, opts: opts, inner: nil}}
    else
      {:error, {:driver_unavailable, backend}}
    end
  end

  @impl true
  def boot(state, spec) do
    backend = state.backend
    opts = flame_opts(state.opts, spec)

    cond do
      not function_exported?(backend, :init, 1) ->
        {:error, {:driver_unavailable, backend}}

      not Keyword.has_key?(opts, :terminator_sup) ->
        {:error, {:provisioner_not_ready, backend}}

      true ->
        with {:ok, inner} <- backend.init(opts),
             {:ok, term, inner} <- backend.remote_boot(inner) do
          machine = %Machine{
            id: inspect(term),
            driver: driver_name(backend),
            pid: term,
            meta: %{backend: backend}
          }

          {:ok, machine, %{state | inner: inner}}
        end
    end
  end

  @impl true
  def await(state, machine, _timeout), do: {:ok, machine, state}

  @impl true
  def shutdown(%{backend: backend, inner: inner}, _machine)
      when inner != nil and is_atom(backend) do
    if function_exported?(backend, :system_shutdown, 0) do
      backend.system_shutdown()
    else
      :ok
    end
  end

  def shutdown(_state, _), do: :ok

  @impl true
  def describe(_state, machine), do: {:ok, Map.from_struct(machine)}

  defp driver_name(FLAME.FlyBackend), do: :fly
  defp driver_name(FLAMEK8sBackend), do: :k8s
  defp driver_name(FlameEC2), do: :ec2
  defp driver_name(mod), do: mod

  defp flame_opts(opts, spec) do
    env = spec[:env] || %{}

    opts
    |> Keyword.put(:env, env)
    |> then(fn kw ->
      if spec[:image], do: Keyword.put(kw, :image, spec[:image]), else: kw
    end)
  end
end
