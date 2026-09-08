defmodule Crucible.Driver.Stacks do
  @moduledoc """
  Stacks node driver for Crucible.

  Provisions signer nodes, API nodes, and sBTC relay infrastructure
  across cloud providers using Stacks-specific cloud-init templates.

  ## Examples

      {:ok, state} = Crucible.init(driver: :stacks, provider: :hetzner, token: System.fetch_env!("HCLOUD_TOKEN"))
      {:ok, machine, state} = Crucible.boot(state, %{
        kind: :stacks_signer,
        region: "nbg1",
        image: "ubuntu-24.04",
        size: "cpx21",
        env: %{
          "STACKS_PRIVATE_KEY" => System.fetch_env!("STACKS_PRIVATE_KEY"),
          "STACKS_POX_V1" => "true"
        }
      })
      {:ok, machine, state} = Crucible.await(state, machine, 300_000)
      :ok = Crucible.shutdown(state, machine)

  Supported kinds:
  - `:stacks_signer` — PoX-5 signer node
  - `:stacks_api` — API/RPC node with chain sync
  - `:stacks_sbtc_relay` — sBTC relay infrastructure

  Supported providers:
  - `:hetzner`, `:digitalocean`, `:aws`, `:vultr`, `:linode`, `:civo`, `:scaleway`
  """
  @behaviour Crucible.Driver

  alias Crucible.{HTTP, Machine, CloudInit}
  require Logger

  @impl true
  def init(opts) do
    provider = Keyword.get(opts, :provider, :hetzner)
    token = Keyword.get(opts, :token) || System.get_env("#{provider_upcase(provider)}_TOKEN")

    {:ok,
     %{
       provider: provider,
       token: token,
       http: Keyword.get(opts, :http),
       opts: opts
     }}
  end

  @impl true
  def boot(state, spec) do
    kind = spec[:kind] || :stacks_api
    provider = state.provider

    with :ok <- need_token(state),
         {:ok, provider_state} <- init_provider(state, spec),
         {:ok, %{status: status, body: body}} when status in [200, 201] <-
           boot_provider(provider_state, spec, kind) do
      machine = to_machine(body, provider, kind)
      {:ok, machine, state}
    else
      {:error, _} = err -> err
      {:ok, %{status: status, body: body}} -> {:error, {:stacks_http, provider, status, body}}
    end
  end

  @impl true
  def await(state, machine, timeout \\ 300_000) do
    provider = state.provider
    deadline = System.monotonic_time(:millisecond) + timeout

    poll(state, machine, provider, deadline)
  end

  @impl true
  def shutdown(state, %Machine{id: id, driver: driver}) do
    provider = driver || state.provider

    with :ok <- need_token(state),
         {:ok, provider_state} <- init_provider(state, %{}),
         {:ok, %{status: status}} when status in [200, 202, 204} <-
           shutdown_provider(provider_state, id) do
      :ok
    else
      {:error, _} = err -> err
      {:ok, %{status: status, body: body}} -> {:error, {:stacks_http, provider, status, body}}
    end
  end

  @impl true
  def describe(state, %Machine{id: id, driver: driver}) do
    provider = driver || state.provider

    with {:ok, provider_state} <- init_provider(state, %{}),
         {:ok, %{status: 200, body: body}} <- describe_provider(provider_state, id) do
      {:ok, Map.from_struct(to_machine(body, provider))}
    else
      {:error, _} = err -> err
      {:ok, %{status: status, body: body}} -> {:error, {:stacks_http, provider, status, body}}
    end
  end

  defp init_provider(state, spec) do
    case state.provider do
      :hetzner -> Crucible.Driver.Hetzner.init(state.opts)
      :digitalocean -> Crucible.Driver.DigitalOcean.init(state.opts)
      :aws -> Crucible.Driver.AWS.init(state.opts)
      :vultr -> Crucible.Driver.Vultr.init(state.opts)
      :linode -> Crucible.Driver.Linode.init(state.opts)
      :civo -> Crucible.Driver.Civo.init(state.opts)
      :scaleway -> Crucible.Driver.Scaleway.init(state.opts)
      _ -> {:error, {:unsupported_provider, state.provider}}
    end
  end

  defp boot_provider(provider_state, spec, kind) do
    provider_state
    |> Map.get(:provider, :unknown)
    |> case do
      :hetzner -> boot_hetzner(provider_state, spec, kind)
      :digitalocean -> boot_digitalocean(provider_state, spec, kind)
      :aws -> boot_aws(provider_state, spec, kind)
      _ -> {:error, {:provider_not_configured, state.provider}}
    end
  end

  defp boot_hetzner(state, spec, kind) do
    body = %{
      name: spec[:name] || "stacks-#{kind}-#{System.unique_integer([:positive])}",
      server_type: spec[:size] || state.opts[:size] || "cpx21",
      image: spec[:image] || state.opts[:image] || "ubuntu-24.04",
      location: spec[:region] || state.opts[:region] || "nbg1",
      start_after_create: true,
      user_data: CloudInit.from_env(stacks_cloud_init(spec, kind)),
      labels: %{"managed-by" => "crucible", "stacks-kind" => to_string(kind)}
    }

    http(state, :post, "https://api.hetzner.cloud/v1/servers", json: body)
  end

  defp boot_digitalocean(state, spec, kind) do
    body = %{
      name: spec[:name] || "stacks-#{kind}-#{System.unique_integer([:positive])}",
      size: spec[:size] || state.opts[:size] || "s-2vcpu-4gb",
      image: spec[:image] || state.opts[:image] || "ubuntu-24.04",
      region: spec[:region] || state.opts[:region] || "nyc1",
      user_data: CloudInit.from_env(stacks_cloud_init(spec, kind)),
      tags: ["crucible", "stacks", to_string(kind)]
    }

    http(state, :post, "https://api.digitalocean.com/v2/droplets", json: body)
  end

  defp boot_aws(state, spec, kind) do
    # AWS requires signing; delegate to existing AWS driver
    {:error, {:aws_requires_signing, "Use Crucible.Driver.AWS directly for Stacks"}}
  end

  defp shutdown_provider(state, id) do
    case Map.get(state, :provider, :unknown) do
      :hetzner -> http(state, :delete, "https://api.hetzner.cloud/v1/servers/#{id}")
      :digitalocean -> http(state, :delete, "https://api.digitalocean.com/v2/droplets/#{id}")
      _ -> {:error, {:provider_not_configured, state.provider}}
    end
  end

  defp describe_provider(state, id) do
    case Map.get(state, :provider, :unknown) do
      :hetzner -> http(state, :get, "https://api.hetzner.cloud/v1/servers/#{id}")
      :digitalocean -> http(state, :get, "https://api.digitalocean.com/v2/droplets/#{id}")
      _ -> {:error, {:provider_not_configured, state.provider}}
    end
  end

  defp poll(state, machine, provider, deadline) do
    if System.monotonic_time(:millisecond) > deadline do
      {:error, :await_timeout}
    else
      case describe_provider(state, machine.id) do
        {:ok, %{status: 200, body: body}} ->
          m = to_machine(body, provider)

          if m.state == :running and is_binary(m.ip) do
            case stacks_health_check(m.ip) do
              :ok -> {:ok, m, state}
              :waiting -> Process.sleep(200); poll(state, m, provider, deadline)
              {:error, _} -> Process.sleep(200); poll(state, m, provider, deadline)
            end
          else
            Process.sleep(200)
            poll(state, m, provider, deadline)
          end

        {:ok, %{status: status, body: body}} ->
          {:error, {:stacks_http, provider, status, body}}

        {:error, _} = err ->
          err
      end
    end
  end

  defp stacks_health_check(ip) do
    timeout = 2_000

    case :httpc.request(:get, {"http://#{ip}:3999/v2/info", []}, [], timeout: timeout) do
      {:ok, {{_, 200, _}, _, _}} -> :ok
      {:ok, {{_, _, _}, _, _}} -> :waiting
      {:error, :timeout} -> :waiting
      {:error, _} -> {:error, :health_check_failed}
    end
  rescue
    _ -> :waiting
  end

  defp to_machine(body, provider, kind \\ :stacks_api) do
    ip = extract_ip(body, provider)
    status = extract_status(body, provider)

    %Machine{
      id: extract_id(body, provider),
      name: extract_name(body, provider),
      driver: :stacks,
      ip: ip,
      state: map_status(status),
      kind: kind,
      extra: body
    }
  end

  defp extract_id(body, :hetzner), do: to_string(body["server"]["id"] || body["id"] || "0")
  defp extract_id(body, :digitalocean), do: to_string(body["droplet"]["id"] || body["id"] || "0")
  defp extract_id(body, _), do: to_string(body["id"] || "0")

  defp extract_name(body, :hetzner), do: body["server"]["name"] || body["name"]
  defp extract_name(body, :digitalocean), do: body["droplet"]["name"] || body["name"]
  defp extract_name(body, _), do: body["name"]

  defp extract_ip(body, :hetzner), do: get_in(body, ["server", "public_net", "ipv4", "ip"])
  defp extract_ip(body, :digitalocean), do: extract_do_ip(body["droplet"]["networks"])
  defp extract_ip(body, _), do: body["ip"]

  defp extract_do_ip(nil), do: nil
  defp extract_do_ip(networks) when is_list(networks) do
    Enum.find_value(networks, fn net ->
      if net["type"] == "public" and net["ip_address"], do: net["ip_address"]
    end)
  end
  defp extract_do_ip(_), do: nil

  defp extract_status(body, :hetzner), do: body["server"]["status"] || body["status"] || "unknown"
  defp extract_status(body, :digitalocean), do: body["droplet"]["status"] || body["status"] || "unknown"
  defp extract_status(body, _), do: body["status"] || "unknown"

  defp map_status("running" <> _), do: :running
  defp map_status("active" <> _), do: :running
  defp map_status("starting" <> _), do: :starting
  defp map_status("initializing" <> _), do: :starting
  defp map_status("off" <> _), do: :stopped
  defp map_status("stopped" <> _), do: :stopped
  defp map_status("deleting" <> _), do: :stopping
  defp map_status("archived" <> _), do: :stopped
  defp map_status(_), do: :unknown

  defp need_token(%{token: token}) when is_binary(token) and token != "", do: :ok
  defp need_token(%{http: fun}) when is_function(fun, 3), do: :ok
  defp need_token(_), do: {:error, :stacks_token_required}

  defp http(state, method, url, extra \\ []) do
    opts =
      extra
      |> Keyword.put(:headers, HTTP.json_headers(state.token || "test"))
      |> Keyword.put(:http, state.http)

    HTTP.request(method, url, opts)
  end

  defp provider_upcase(:hetzner), do: "HCLOUD"
  defp provider_upcase(:digitalocean), do: "DIGITALOCEAN"
  defp provider_upcase(:aws), do: "AWS"
  defp provider_upcase(:vultr), do: "VULTR"
  defp provider_upcase(:linode), do: "LINODE"
  defp provider_upcase(:civo), do: "CIVO"
  defp provider_upcase(:scaleway), do: "SCALEWAY"
  defp provider_upcase(_), do: "PROVIDER"

  defp stacks_cloud_init(spec, kind) do
    env = spec[:env] || %{}
    CloudInit.from_env(env)
  end
end
