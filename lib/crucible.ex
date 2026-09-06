defmodule Crucible do
  @moduledoc """
  Multi-cloud provisioner for Phoenix FLAME.

  Cloud HTTP drivers create machines. Iroh/Zenoh only join them.
  Design survey: `DESIGN.md`.

      {:ok, state} = Crucible.init(driver: :local)
      {:ok, machine, state} = Crucible.boot(state, %{env: %{}})
      :ok = Crucible.shutdown(state, machine)

  `driver:` any name in `Crucible.providers/0` (100+). Implemented: local,
  dummy, docker, hetzner, digitalocean, vultr, linode, civo, scaleway,
  plus wraps fly/k8s/ec2.
  """

  alias Crucible.{Driver, Machine}

  def init(opts) when is_list(opts) do
    {mod, driver_opts} = Driver.resolve(opts)

    with {:ok, inner} <- mod.init(driver_opts) do
      {:ok, %{driver: mod, inner: inner, opts: opts}}
    end
  end

  def boot(state, spec \\ %{}) when is_map(spec) do
    spec = Driver.normalize_spec(spec, state.opts)

    with {:ok, %Machine{} = machine, inner} <- state.driver.boot(state.inner, spec) do
      {:ok, machine, %{state | inner: inner}}
    end
  end

  def await(state, machine, timeout \\ 30_000) do
    with {:ok, machine, inner} <- state.driver.await(state.inner, machine, timeout) do
      {:ok, machine, %{state | inner: inner}}
    end
  end

  def shutdown(state, machine) do
    state.driver.shutdown(state.inner, machine)
  end

  def describe(state, machine) do
    state.driver.describe(state.inner, machine)
  end

  def providers, do: Crucible.Providers.names()

  def drivers do
    Map.new(Crucible.Providers.names(), fn name ->
      {name, Crucible.Providers.implemented?(name)}
    end)
  end

  def list_sizes(state) do
    if function_exported?(state.driver, :list_sizes, 1) do
      state.driver.list_sizes(state.inner)
    else
      {:error, :not_supported}
    end
  end

  @doc "Libcloud-style factory. `Crucible.get_driver(:dummy)`."
  def get_driver(provider), do: elem(Crucible.Driver.resolve(driver: provider), 0)
end
