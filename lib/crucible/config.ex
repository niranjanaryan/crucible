defmodule Crucible.Config do
  @moduledoc """
  Load credentials from `.env` and YAML/JSON config files.

  Search (cwd, then `~/.config/crucible/`):

  * `.env`, `.env.local` — `KEY=value` (does not override existing env)
  * `crucible.yaml`, `crucible.yml`, `.crucible.yaml`, `crucible.json`

  Flags `--config` / `--env-file` win. CLI flags override the file.

      # crucible.yaml
      driver: hetzner
      region: nbg1
      size: cpx21
      # token from env HCLOUD_TOKEN, or:
      token: "…"

      # nested per-driver
      hetzner:
        token: "…"
        region: nbg1
  """

  @config_names ~w(crucible.yaml crucible.yml .crucible.yaml crucible.json)
  @env_names ~w(.env .env.local)

  def load(opts) when is_list(opts) do
    env_file = opts[:env_file]
    config_file = opts[:config]
    _ = load_dotenv(env_file)
    file = load_config_file(config_file)
    merge(file, opts)
  end

  def load_dotenv(explicit) do
    paths =
      case explicit do
        path when is_binary(path) and path != "" -> [path]
        _ -> env_search_paths()
      end

    Enum.each(paths, &apply_env_file/1)
    :ok
  end

  def load_config_file(explicit) do
    path =
      case explicit do
        path when is_binary(path) and path != "" -> path
        _ -> Enum.find(config_search_paths(), &File.regular?/1)
      end

    cond do
      is_nil(path) ->
        %{}

      true ->
        warn_insecure!(path)
        if String.ends_with?(path, ".json"), do: read_json(path), else: read_yaml(path)
    end
  end

  def merge(file, cli) when is_map(file) and is_list(cli) do
    driver = cli[:driver] || file["driver"] || file[:driver]
    nested = driver_section(file, driver)

    cli_env =
      cli
      |> Keyword.get_values(:env)
      |> Enum.filter(&is_binary/1)
      |> Enum.map(fn pair ->
        case String.split(pair, "=", parts: 2) do
          [k, v] -> {k, v}
          [k] -> {k, ""}
        end
      end)
      |> Map.new()

    env = Map.merge(env_map(nested["env"] || file["env"]), cli_env)

    from_file =
      [
        driver: as_atom(driver),
        token: nested["token"] || file["token"],
        access_key: nested["access_key"] || file["access_key"],
        secret_key: nested["secret_key"] || file["secret_key"],
        region: nested["region"] || file["region"],
        size: nested["size"] || file["size"],
        image: nested["image"] || file["image"],
        name: nested["name"] || file["name"],
        env: env
      ]
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == %{} end)

    cli_clean =
      Enum.reject(cli, fn
        {:env, _} -> true
        {_k, v} -> is_nil(v)
      end)

    from_file
    |> Keyword.merge(cli_clean)
    |> Keyword.update(:driver, nil, &as_atom/1)
  end

  defp driver_section(file, driver) when is_binary(driver) or is_atom(driver) do
    key = to_string(driver)

    case file[key] || file[String.to_atom(key)] do
      map when is_map(map) -> stringify_keys(map)
      _ -> %{}
    end
  end

  defp driver_section(_, _), do: %{}

  defp env_map(nil), do: %{}

  defp env_map(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), to_string(v)} end)
  end

  defp stringify_keys(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  defp as_atom(nil), do: nil
  defp as_atom(a) when is_atom(a), do: a
  defp as_atom(s) when is_binary(s), do: String.to_atom(s)

  defp env_search_paths do
    cwd = File.cwd!()
    Enum.map(@env_names, &Path.join(cwd, &1))
  end

  defp config_search_paths do
    cwd = File.cwd!()
    home = Path.expand("~/.config/crucible")

    Enum.map(@config_names, &Path.join(cwd, &1)) ++
      Enum.map(~w(config.yaml config.yml config.json), &Path.join(home, &1))
  end

  defp apply_env_file(path) do
    if File.regular?(path) do
      warn_insecure!(path)

      path
      |> File.read!()
      |> String.split("\n")
      |> Enum.each(&put_env_line/1)
    end
  end

  defp put_env_line(line) do
    line = String.trim(line)

    cond do
      line == "" ->
        :ok

      String.starts_with?(line, "#") ->
        :ok

      true ->
        case String.split(line, "=", parts: 2) do
          [k, v] ->
            k = String.trim(k)
            v = v |> String.trim() |> unquote_scalar()

            if k != "" and is_nil(System.get_env(k)) do
              System.put_env(k, v)
            end

          _ ->
            :ok
        end
    end
  end

  defp warn_insecure!(path) do
    case File.stat(path) do
      {:ok, %{mode: mode}} ->
        if Bitwise.band(mode, 0o077) != 0 do
          IO.puts(:stderr, "warning: #{path} is group/world readable; chmod 600")
        end

      _ ->
        :ok
    end
  end

  defp read_json(path) do
    case Jason.decode(File.read!(path)) do
      {:ok, map} when is_map(map) -> map
      _ -> %{}
    end
  end

  defp read_yaml(path) do
    parse_simple_yaml(File.read!(path))
  end

  # Two-level maps of scalars — enough for credentials. Not a full YAML 1.1 parser.
  def parse_simple_yaml(text) when is_binary(text) do
    text
    |> String.split("\n")
    |> Enum.reduce({%{}, nil}, fn line, {acc, section} ->
      raw = String.trim_trailing(line, "\n")
      trimmed = String.trim(raw)

      cond do
        trimmed == "" or String.starts_with?(trimmed, "#") ->
          {acc, section}

        String.starts_with?(raw, "  ") or String.starts_with?(raw, "\t") ->
          case parse_kv(trimmed) do
            {k, v} when is_binary(section) ->
              nested = Map.get(acc, section, %{})
              {Map.put(acc, section, Map.put(nested, k, v)), section}

            _ ->
              {acc, section}
          end

        true ->
          case parse_kv(trimmed) do
            {k, nil} -> {Map.put_new(acc, k, %{}), k}
            {k, v} -> {Map.put(acc, k, v), nil}
            :error -> {acc, section}
          end
      end
    end)
    |> elem(0)
  end

  defp parse_kv(line) do
    case String.split(line, ":", parts: 2) do
      [k] ->
        {String.trim(k), nil}

      [k, rest] ->
        rest = String.trim(rest)

        cond do
          rest == "" -> {String.trim(k), nil}
          true -> {String.trim(k), unquote_scalar(rest)}
        end

      _ ->
        :error
    end
  end

  defp unquote_scalar(v) do
    v = String.trim(v)

    cond do
      String.starts_with?(v, "\"") and String.ends_with?(v, "\"") ->
        v |> String.slice(1..-2//1) |> unescape()

      String.starts_with?(v, "'") and String.ends_with?(v, "'") ->
        String.slice(v, 1..-2//1)

      v in ["true", "True"] ->
        "true"

      v in ["false", "False"] ->
        "false"

      true ->
        v
    end
  end

  defp unescape(s) do
    s
    |> String.replace("\\\"", "\"")
    |> String.replace("\\n", "\n")
  end
end
