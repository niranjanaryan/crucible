defmodule Crucible.Driver do
  @moduledoc """
  Libcloud-shaped compute driver.

  Implement in optional packages (`crucible_hetzner`, …) or wrap an
  existing `FLAME.Backend` (`FLAME.FlyBackend`, `FLAMEK8sBackend`).
  """

  alias Crucible.Machine

  @type spec :: map()
  @type state :: term()

  @callback init(Keyword.t()) :: {:ok, state} | {:error, term()}
  @callback boot(state, spec) :: {:ok, Machine.t(), state} | {:error, term()}
  @callback await(state, Machine.t(), timeout) :: {:ok, Machine.t(), state} | {:error, term()}
  @callback shutdown(state, Machine.t()) :: :ok | {:error, term()}
  @callback describe(state, Machine.t()) :: {:ok, map()} | {:error, term()}

  def resolve(opts) do
    driver_opts = Keyword.drop(opts, [:driver, :overlay, :provisioner])

    case Keyword.get(opts, :driver, :local) do
      {mod, extra} when is_atom(mod) and is_list(extra) ->
        {mod, Keyword.merge(driver_opts, extra)}

      name when is_atom(name) ->
        resolve_name(name, driver_opts)
    end
  end

  defp resolve_name(name, driver_opts) do
    case Crucible.Providers.get(name) do
      %{kind: :builtin, module: mod} ->
        {mod, driver_opts}

      %{kind: :wrap, backend: backend} ->
        {Crucible.Driver.Wrap, Keyword.put(driver_opts, :backend, backend)}

      %{kind: :rest} ->
        {Crucible.Driver.REST, Keyword.put(driver_opts, :provider, name)}

      %{kind: :catalog} = meta ->
        {Crucible.Driver.Catalog, Keyword.merge(driver_opts, provider: name, meta: meta)}

      nil ->
        {Crucible.Driver.Catalog, Keyword.merge(driver_opts, provider: name, meta: %{})}
    end
  end

  def normalize_spec(spec, opts) when is_map(spec) and is_list(opts) do
    spec
    |> Map.put_new(:image, Keyword.get(opts, :image))
    |> Map.put_new(:size, Keyword.get(opts, :size))
    |> Map.put_new(:region, Keyword.get(opts, :region))
    |> Map.update(:env, env_map(opts), &Map.merge(env_map(opts), &1))
  end

  defp env_map(opts) do
    opts
    |> Keyword.get(:env, %{})
    |> Map.new(fn
      {k, v} when is_atom(k) -> {to_string(k), to_string(v)}
      {k, v} -> {to_string(k), to_string(v)}
    end)
  end
end
