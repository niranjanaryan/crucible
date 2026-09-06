defmodule Crucible.Driver.Hetzner do
  @moduledoc """
  Hetzner Cloud servers. Libcloud never shipped this driver.

      Crucible.init(
        driver: :hetzner,
        token: System.get_env("HCLOUD_TOKEN"),
        size: "cpx21",
        image: "ubuntu-24.04",
        region: "nbg1"
      )

  API: `https://api.hetzner.cloud/v1`. Tests inject `:http`.
  """
  @behaviour Crucible.Driver

  alias Crucible.{HTTP, Machine, CloudInit}

  @base "https://api.hetzner.cloud/v1"

  @impl true
  def init(opts) do
    token = Keyword.get(opts, :token) || System.get_env("HCLOUD_TOKEN")

    {:ok,
     %{
       token: token,
       http: Keyword.get(opts, :http),
       opts: opts
     }}
  end

  @impl true
  def boot(state, spec) do
    with :ok <- need_token(state),
         {:ok, %{status: status, body: body}} when status in [200, 201] <-
           http(state, :post, @base <> "/servers", json: create_body(state, spec)) do
      server = body["server"] || %{}
      {:ok, to_machine(server), state}
    else
      {:error, _} = err -> err
      {:ok, %{status: status, body: body}} -> {:error, {:hetzner_http, status, body}}
    end
  end

  @impl true
  def await(state, machine, timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout
    poll(state, machine, deadline)
  end

  @impl true
  def shutdown(state, %Machine{id: id}) do
    with :ok <- need_token(state),
         {:ok, %{status: status}} when status in [200, 202, 204] <-
           http(state, :delete, @base <> "/servers/#{id}") do
      :ok
    else
      {:error, _} = err -> err
      {:ok, %{status: status, body: body}} -> {:error, {:hetzner_http, status, body}}
    end
  end

  @impl true
  def describe(state, %Machine{id: id}) do
    case http(state, :get, @base <> "/servers/#{id}") do
      {:ok, %{status: 200, body: body}} ->
        {:ok, Map.from_struct(to_machine(body["server"] || %{}))}

      {:ok, %{status: status, body: body}} ->
        {:error, {:hetzner_http, status, body}}

      {:error, _} = err ->
        err
    end
  end

  def list_sizes(state) do
    case http(state, :get, @base <> "/server_types") do
      {:ok, %{status: 200, body: %{"server_types" => types}}} ->
        {:ok,
         Enum.map(types, fn t ->
           %Crucible.Size{
             id: t["name"],
             name: t["description"] || t["name"],
             ram: t["memory"] && t["memory"] * 1024,
             cpu: t["cores"],
             disk: t["disk"],
             extra: t
           }
         end)}

      other ->
        other
    end
  end

  defp poll(state, machine, deadline) do
    if System.monotonic_time(:millisecond) > deadline do
      {:error, :await_timeout}
    else
      case http(state, :get, @base <> "/servers/#{machine.id}") do
        {:ok, %{status: 200, body: %{"server" => server}}} ->
          m = to_machine(server)

          if m.state == :running and is_binary(m.ip) do
            {:ok, m, state}
          else
            Process.sleep(200)
            poll(state, m, deadline)
          end

        {:ok, %{status: status, body: body}} ->
          {:error, {:hetzner_http, status, body}}

        {:error, _} = err ->
          err
      end
    end
  end

  defp create_body(state, spec) do
    env = spec[:env] || %{}

    %{
      name: spec[:name] || "crucible-#{System.unique_integer([:positive])}",
      server_type: spec[:size] || state.opts[:size] || "cpx11",
      image: spec[:image] || state.opts[:image] || "ubuntu-24.04",
      location: spec[:region] || state.opts[:region] || "nbg1",
      start_after_create: true,
      user_data: CloudInit.from_env(env),
      labels: %{"managed-by" => "crucible"}
    }
  end

  defp to_machine(server) when is_map(server) do
    pub = get_in(server, ["public_net", "ipv4", "ip"])
    status = server["status"] || "unknown"

    %Machine{
      id: to_string(server["id"] || "0"),
      name: server["name"],
      driver: :hetzner,
      ip: pub,
      state: map_status(status),
      extra: server
    }
  end

  defp map_status("running"), do: :running
  defp map_status("initializing"), do: :starting
  defp map_status("starting"), do: :starting
  defp map_status("off"), do: :stopped
  defp map_status("deleting"), do: :stopping
  defp map_status(_), do: :unknown

  defp need_token(%{token: token}) when is_binary(token) and token != "", do: :ok
  defp need_token(%{http: fun}) when is_function(fun, 3), do: :ok
  defp need_token(_), do: {:error, :hetzner_token_required}

  defp http(state, method, url, extra \\ []) do
    opts =
      extra
      |> Keyword.put(:headers, HTTP.json_headers(state.token || "test"))
      |> Keyword.put(:http, state.http)

    HTTP.request(method, url, opts)
  end
end
