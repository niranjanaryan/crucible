defmodule Crucible.CLI do
  @moduledoc """
  Standalone CLI (`crucible`) and Mix task (`mix crucible`). Same pattern as Orian.
  """

  @version Mix.Project.config()[:version]

  @help """
  crucible #{@version} — multi-cloud provisioner (Libcloud-shaped)

    crucible ls | providers [--implemented] [--production] [--kind KIND] [--json]
    crucible boot      --driver NAME [--token T | --access-key AK --secret-key SK] [--region R] [--name N] [--image I] [--size S] [--env K=V] [--json]
    crucible describe  --driver NAME --id ID [--json]
    crucible rm | shutdown --driver NAME --id ID
    crucible sizes     --driver NAME [--json]
    crucible http
    crucible version

  Drivers: dummy, local, docker, hetzner, digitalocean, vultr, linode, fly, k8s, …
  KIND: rest | wrap | builtin | catalog

  Config: crucible.yaml | crucible.json | .env   (cwd or ~/.config/crucible/)
          --config PATH --env-file PATH

  Env: HCLOUD_TOKEN DIGITALOCEAN_TOKEN VULTR_API_KEY LINODE_TOKEN
       AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION FLY_API_TOKEN

  Install: mix crucible.install
    Linux/macOS: ~/.local/bin
    Windows:     %LOCALAPPDATA%\\elixcoder\\bin
    Override:    ELIXCODER_BIN
  """

  @switches [
    driver: :string,
    name: :string,
    image: :string,
    size: :string,
    region: :string,
    token: :string,
    access_key: :string,
    secret_key: :string,
    id: :string,
    env: :keep,
    json: :boolean,
    implemented: :boolean,
    kind: :string,
    config: :string,
    env_file: :string,
    production: :boolean,
    force: :boolean,
    help: :boolean,
    version: :boolean
  ]

  @aliases [d: :driver, n: :name, i: :image, s: :size, r: :region, h: :help, v: :version]

  def main(args), do: main(args, halt: !mix?())

  def main(args, opts) do
    _ = Application.ensure_all_started(:crucible)
    _ = Application.ensure_all_started(:req)
    _ = Application.ensure_all_started(:jason)

    result = dispatch(args)
    finish(result, Keyword.get(opts, :halt, false))
  end

  defp dispatch(["help" | _]), do: info(@help)
  defp dispatch(["--help"]), do: info(@help)
  defp dispatch(["-h"]), do: info(@help)
  defp dispatch(["version" | _]), do: info("crucible #{@version}")
  defp dispatch(["--version"]), do: info("crucible #{@version}")
  defp dispatch([]), do: info(@help)

  defp dispatch(["providers" | rest]), do: cmd_providers(rest)
  defp dispatch(["ls" | rest]), do: cmd_providers(rest)
  defp dispatch(["boot" | rest]), do: cmd_boot(rest)
  defp dispatch(["shutdown" | rest]), do: cmd_shutdown(rest)
  defp dispatch(["rm" | rest]), do: cmd_shutdown(rest)
  defp dispatch(["destroy" | rest]), do: cmd_shutdown(rest)
  defp dispatch(["describe" | rest]), do: cmd_describe(rest)
  defp dispatch(["sizes" | rest]), do: cmd_sizes(rest)
  defp dispatch(["http" | _]), do: cmd_http()

  defp dispatch([cmd | _]) do
    err("unknown command: #{cmd}")
    info(@help)
    {:error, :unknown_command}
  end

  defp cmd_http do
    info(to_string(Crucible.HTTP.client()))
    :ok
  end

  defp cmd_providers(args) do
    {opts, _, _} = OptionParser.parse(args, strict: @switches, aliases: @aliases)
    if opts[:help], do: info(@help), else: do_providers(opts)
  end

  defp do_providers(opts) do
    kind_filter = opts[:kind]

    rows =
      Crucible.providers()
      |> Enum.map(fn name ->
        meta = Crucible.Providers.get(name) || %{}
        {name, meta[:kind] || :catalog, Crucible.Providers.implemented?(name)}
      end)
      |> Enum.filter(fn {name, kind, impl} ->
        (is_nil(kind_filter) or to_string(kind) == kind_filter) and
          (not Keyword.get(opts, :implemented, false) or impl) and
          (not Keyword.get(opts, :production, false) or Crucible.Providers.production_ready?(name))
      end)

    if opts[:json] do
      info(
        Jason.encode!(Enum.map(rows, fn {n, k, i} -> %{driver: n, kind: k, implemented: i} end))
      )
    else
      info("#{length(rows)} providers (#{Crucible.Providers.count()} total)")

      Enum.each(rows, fn {name, kind, impl} ->
        mark = if impl, do: "*", else: " "
        puts_pipe("  #{mark} " <> String.pad_trailing(to_string(name), 24) <> to_string(kind))
      end)
    end

    :ok
  end

  defp cmd_boot(args) do
    {opts, _, _} = OptionParser.parse(args, strict: @switches, aliases: @aliases)
    opts = Crucible.Config.load(opts)

    with {:ok, driver} <- fetch_driver(opts),
         :ok <- production_guard(driver, opts),
         {:ok, state} <- Crucible.init(init_opts(driver, opts)),
         {:ok, machine, state} <- Crucible.boot(state, boot_spec(opts)),
         {:ok, machine, _} <- maybe_await(state, machine) do
      print_machine(machine, opts)
      :ok
    end
  end

  defp cmd_shutdown(args) do
    {opts, _, _} = OptionParser.parse(args, strict: @switches, aliases: @aliases)
    opts = Crucible.Config.load(opts)

    with {:ok, driver} <- fetch_driver(opts),
         {:ok, id} <- fetch_id(opts),
         {:ok, state} <- Crucible.init(init_opts(driver, opts)) do
      machine = %Crucible.Machine{id: id, driver: driver}
      Crucible.shutdown(state, machine)
      info("shutdown #{id}")
      :ok
    end
  end

  defp cmd_describe(args) do
    {opts, _, _} = OptionParser.parse(args, strict: @switches, aliases: @aliases)
    opts = Crucible.Config.load(opts)

    with {:ok, driver} <- fetch_driver(opts),
         {:ok, id} <- fetch_id(opts),
         {:ok, state} <- Crucible.init(init_opts(driver, opts)) do
      machine = %Crucible.Machine{id: id, driver: driver}

      case Crucible.describe(state, machine) do
        {:ok, info} ->
          print_term(info, opts)
          :ok

        other ->
          other
      end
    end
  end

  defp cmd_sizes(args) do
    {opts, _, _} = OptionParser.parse(args, strict: @switches, aliases: @aliases)
    opts = Crucible.Config.load(opts)

    with {:ok, driver} <- fetch_driver(opts),
         {:ok, state} <- Crucible.init(init_opts(driver, opts)) do
      case Crucible.list_sizes(state) do
        {:ok, sizes} ->
          print_term(sizes, opts)
          :ok

        other ->
          other
      end
    end
  end

  defp production_guard(driver, opts) do
    cond do
      Keyword.get(opts, :force, false) ->
        :ok

      Keyword.get(opts, :production, false) and not Crucible.Providers.production_ready?(driver) ->
        {:error, {:not_production_ready, driver}}

      not Crucible.Providers.production_ready?(driver) and not Keyword.get(opts, :force, false) ->
        err("driver #{driver} is experimental; use --production to block non-allowlisted drivers")
        :ok

      true ->
        :ok
    end
  end

  defp fetch_driver(opts) do
    case opts[:driver] do
      nil -> {:error, :driver_required}
      name when is_atom(name) -> {:ok, name}
      name when is_binary(name) -> {:ok, String.to_atom(name)}
    end
  end

  defp fetch_id(opts) do
    case opts[:id] do
      nil -> {:error, :id_required}
      id -> {:ok, id}
    end
  end

  defp init_opts(driver, opts) do
    [driver: driver, token: opts[:token]]
    |> Keyword.merge(
      image: opts[:image],
      size: opts[:size],
      region: opts[:region],
      access_key: opts[:access_key],
      secret_key: opts[:secret_key]
    )
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end

  defp boot_spec(opts) do
    from_flags =
      opts
      |> Keyword.get_values(:env)
      |> Enum.map(&split_env/1)
      |> Map.new()

    env = Map.merge(opts[:env] || %{}, from_flags)

    %{
      name: opts[:name],
      image: opts[:image],
      size: opts[:size],
      region: opts[:region],
      env: env
    }
    |> Map.reject(fn {_k, v} -> is_nil(v) or v == %{} end)
  end

  defp split_env(pair) do
    case String.split(pair, "=", parts: 2) do
      [k, v] -> {k, v}
      [k] -> {k, ""}
    end
  end

  defp maybe_await(state, machine) do
    if machine.driver in [:local, :dummy] do
      {:ok, machine, state}
    else
      Crucible.await(state, machine, 30_000)
    end
  end

  defp print_machine(machine, opts) do
    print_term(Map.from_struct(machine) |> Map.drop([:pid, :extra]), opts)
  end

  defp print_term(term, opts) do
    if opts[:json] do
      info(Jason.encode!(jsonish(term)))
    else
      IO.inspect(term, pretty: true, limit: 30)
    end
  end

  defp jsonish(%_{} = struct), do: jsonish(Map.from_struct(struct))
  defp jsonish(list) when is_list(list), do: Enum.map(list, &jsonish/1)
  defp jsonish(map) when is_map(map), do: Map.new(map, fn {k, v} -> {k, jsonish(v)} end)
  defp jsonish(other), do: other

  defp puts_pipe(line) do
    IO.puts(line)
  rescue
    ErlangError -> :ok
  end

  defp info(msg) do
    IO.puts(msg)
    :ok
  end

  defp err(msg), do: IO.puts(:stderr, msg)

  defp mix? do
    Code.ensure_loaded?(Mix.Project) and function_exported?(Mix.Project, :get, 0)
  rescue
    _ -> false
  end

  defp finish(:ok, false), do: :ok

  defp finish({:error, reason} = e, false) do
    err(format_error(reason))
    e
  end

  defp finish(:ok, true), do: System.halt(0)

  defp finish({:error, reason}, true) do
    err(format_error(reason))
    System.halt(1)
  end

  defp finish(_, true), do: System.halt(1)

  defp format_error(:driver_required), do: "missing --driver"
  defp format_error(:id_required), do: "missing --id"

  defp format_error({:not_production_ready, d}),
    do: "#{d} is not on the production allowlist (see PRODUCTION.md); use --force to override"

  defp format_error(:unknown_command), do: "unknown command"
  defp format_error(other), do: inspect(other)
end
