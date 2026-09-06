defmodule Crucible.Driver.REST.Json do
  @moduledoc """
  Data-driven JSON REST (Libcloud-style). Paths and keys come from provider meta.
  """

  alias Crucible.{CloudInit, Machine}

  def create(state, spec) do
    meta = state.meta
    path = fill(meta[:create_path] || "/servers", state, spec, nil)
    body = body(state, spec)
    {meta[:create_method] || :post, path, body}
  end

  def get(state, %Machine{} = machine) do
    path = fill(state.meta[:get_path] || "/servers/:id", state, %{}, machine)
    {state.meta[:get_method] || :get, path}
  end

  def delete(state, %Machine{} = machine) do
    path = fill(state.meta[:delete_path] || "/servers/:id", state, %{}, machine)
    {state.meta[:delete_method] || :delete, path}
  end

  def list_sizes(state) do
    path = state.meta[:sizes_path] || "/sizes"
    url = String.trim_trailing(state.meta[:base] || "", "/") <> path

    case Crucible.HTTP.request(:get, url,
           headers: Crucible.Auth.headers(state, :get, url, ""),
           http: state.http
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, sizes_from(body, state.meta)}

      other ->
        other
    end
  end

  def to_machine(body, provider, meta) when is_map(body) do
    wrap = meta[:wrap]
    node = if is_binary(wrap), do: body[wrap] || body, else: body
    id = dig(node, meta[:id_path] || ["id"])
    ip = dig(node, meta[:ip_path] || ["ip"])
    status = dig(node, meta[:status_path] || ["status"])

    %Machine{
      id: to_string(id || ""),
      name:
        dig(node, meta[:name_path] || ["name"]) || dig(node, ["label"]) || dig(node, ["hostname"]),
      driver: provider,
      ip: ip && to_string(ip),
      state: map_status(status, meta[:running] || ["running", "active", "ACTIVE"]),
      extra: Map.put(node, "_meta_paths", true)
    }
  end

  defp sizes_from(body, meta) when is_map(body) do
    key = meta[:sizes_wrap] || "sizes"
    list = body[key] || body["server_types"] || body["plans"] || []

    Enum.map(List.wrap(list), fn
      item when is_map(item) ->
        %Crucible.Size{
          id: to_string(item["id"] || item["name"] || item["slug"] || ""),
          name: item["name"] || item["slug"] || item["id"],
          ram: item["memory"] || item["ram"],
          cpu: item["vcpus"] || item["cores"] || item["cpu"],
          disk: item["disk"],
          extra: item
        }

      other ->
        %Crucible.Size{id: to_string(other)}
    end)
  end

  defp sizes_from(_, _), do: []

  defp body(state, spec) do
    meta = state.meta
    env = spec[:env] || %{}
    user_data = CloudInit.from_env(env)

    base = %{
      name: spec[:name] || "crucible",
      image: spec[:image] || state.opts[:image],
      user_data: user_data
    }

    size_key = meta[:size_key] || "size"
    region_key = meta[:region_key] || "region"

    base
    |> Map.put(String.to_atom(size_key), spec[:size] || state.opts[:size])
    |> Map.put(String.to_atom(region_key), spec[:region] || state.opts[:region])
    |> Map.merge(meta[:extra_body] || %{})
    |> Map.reject(fn {_k, v} -> is_nil(v) end)
  end

  defp fill(path, state, spec, machine) do
    id = machine && machine.id
    zone = spec[:region] || state.opts[:region] || state.meta[:default_region]
    project = state.opts[:project] || state.meta[:project]

    path
    |> String.replace(":id", to_string(id || ""))
    |> String.replace(":zone", to_string(zone || ""))
    |> String.replace(":region", to_string(zone || ""))
    |> String.replace(":project", to_string(project || ""))
  end

  defp dig(map, path) when is_list(path) and is_map(map) do
    Enum.reduce_while(path, map, fn key, acc ->
      key = if is_atom(key), do: to_string(key), else: key

      cond do
        is_map(acc) and is_map_key(acc, key) -> {:cont, acc[key]}
        is_list(acc) -> {:halt, nil}
        true -> {:halt, nil}
      end
    end)
  end

  defp dig(_, _), do: nil

  defp map_status(status, running) when is_binary(status) do
    if status in running, do: :running, else: :unknown
  end

  defp map_status(_, _), do: :unknown
end
