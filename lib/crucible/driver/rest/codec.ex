defmodule Crucible.Driver.REST.Codec do
  @moduledoc false
  alias Crucible.{CloudInit, Machine}

  def get(:digitalocean), do: {:ok, __MODULE__.DigitalOcean}
  def get(:vultr), do: {:ok, __MODULE__.Vultr}
  def get(:linode), do: {:ok, __MODULE__.Linode}
  def get(:civo), do: {:ok, __MODULE__.Civo}
  def get(:scaleway), do: {:ok, __MODULE__.Scaleway}
  def get(:json), do: {:ok, Crucible.Driver.REST.Json}
  def get(:gce), do: {:ok, Crucible.Driver.REST.Codec.GCE}
  def get(other), do: {:error, {:rest_codec_missing, other}}

  defmodule DigitalOcean do
    def create(state, spec) do
      {:post, "/droplets",
       %{
         name: spec[:name] || "crucible",
         region: spec[:region] || state.opts[:region] || "nyc3",
         size: spec[:size] || state.opts[:size] || "s-1vcpu-1gb",
         image: spec[:image] || state.opts[:image] || "ubuntu-24-04-x64",
         user_data: CloudInit.from_env(spec[:env] || %{}),
         tags: ["crucible"]
       }}
    end

    def get(%Machine{id: id}), do: {:get, "/droplets/#{id}"}
    def delete(%Machine{id: id}), do: {:delete, "/droplets/#{id}"}

    def to_machine(body, provider) do
      d = body["droplet"] || body
      ip = v4(d)

      %Machine{
        id: to_string(d["id"] || ""),
        name: d["name"],
        driver: provider,
        ip: ip,
        state: st(d["status"]),
        extra: d
      }
    end

    defp v4(d) do
      nets = get_in(d, ["networks", "v4"]) || []

      case Enum.find(nets, &(&1["type"] == "public")) do
        %{"ip_address" => ip} -> ip
        _ -> nil
      end
    end

    defp st("active"), do: :running
    defp st("new"), do: :starting
    defp st("off"), do: :stopped
    defp st(_), do: :unknown
  end

  defmodule Vultr do
    def create(state, spec) do
      {:post, "/instances",
       %{
         label: spec[:name] || "crucible",
         region: spec[:region] || state.opts[:region] || "ewr",
         plan: spec[:size] || state.opts[:size] || "vc2-1c-1gb",
         os_id: spec[:image] || state.opts[:image] || 1743,
         user_data: CloudInit.from_env(spec[:env] || %{})
       }}
    end

    def get(%Machine{id: id}), do: {:get, "/instances/#{id}"}
    def delete(%Machine{id: id}), do: {:delete, "/instances/#{id}"}

    def to_machine(body, provider) do
      i = body["instance"] || body

      %Machine{
        id: to_string(i["id"] || ""),
        name: i["label"],
        driver: provider,
        ip: i["main_ip"],
        state: st(i["status"] || i["server_status"]),
        extra: i
      }
    end

    defp st("active"), do: :running
    defp st("pending"), do: :pending
    defp st(_), do: :unknown
  end

  defmodule Linode do
    def create(state, spec) do
      {:post, "/linode/instances",
       %{
         label: spec[:name] || "crucible",
         region: spec[:region] || state.opts[:region] || "us-east",
         type: spec[:size] || state.opts[:size] || "g6-nanode-1",
         image: spec[:image] || state.opts[:image] || "linode/ubuntu24.04",
         metadata: %{user_data: Base.encode64(CloudInit.from_env(spec[:env] || %{}))}
       }}
    end

    def get(%Machine{id: id}), do: {:get, "/linode/instances/#{id}"}
    def delete(%Machine{id: id}), do: {:delete, "/linode/instances/#{id}"}

    def to_machine(body, provider) do
      i = if is_map(body) and Map.has_key?(body, "id"), do: body, else: body["linode"] || body
      ipv4 = List.wrap(i["ipv4"]) |> List.first()

      %Machine{
        id: to_string(i["id"] || ""),
        name: i["label"],
        driver: provider,
        ip: ipv4,
        state: st(i["status"]),
        extra: i
      }
    end

    defp st("running"), do: :running
    defp st("provisioning"), do: :starting
    defp st("offline"), do: :stopped
    defp st(_), do: :unknown
  end

  defmodule Civo do
    def create(state, spec) do
      {:post, "/instances",
       %{
         hostname: spec[:name] || "crucible",
         size: spec[:size] || state.opts[:size] || "g3.small",
         template_id: spec[:image] || state.opts[:image],
         region: spec[:region] || state.opts[:region] || "LON1",
         script: CloudInit.from_env(spec[:env] || %{})
       }}
    end

    def get(%Machine{id: id}), do: {:get, "/instances/#{id}"}
    def delete(%Machine{id: id}), do: {:delete, "/instances/#{id}"}

    def to_machine(body, provider) do
      i = body["instance"] || body

      %Machine{
        id: to_string(i["id"] || i["ID"] || ""),
        name: i["hostname"] || i["name"],
        driver: provider,
        ip: i["public_ip"] || i["ip"],
        state: st(i["status"]),
        extra: i
      }
    end

    defp st("ACTIVE"), do: :running
    defp st("active"), do: :running
    defp st(_), do: :unknown
  end

  defmodule Scaleway do
    def create(state, spec) do
      zone = spec[:region] || state.opts[:region] || "fr-par-1"

      {:post, "/zones/#{zone}/servers",
       %{
         name: spec[:name] || "crucible",
         commercial_type: spec[:size] || state.opts[:size] || "DEV1-S",
         image: spec[:image] || state.opts[:image],
         project: state.opts[:project]
       }}
    end

    def get(%Machine{id: id, extra: extra}) do
      zone = extra["zone"] || "fr-par-1"
      {:get, "/zones/#{zone}/servers/#{id}"}
    end

    def delete(%Machine{id: id, extra: extra}) do
      zone = extra["zone"] || "fr-par-1"
      {:delete, "/zones/#{zone}/servers/#{id}"}
    end

    def to_machine(body, provider) do
      s = body["server"] || body
      ip = get_in(s, ["public_ip", "address"])

      %Machine{
        id: to_string(s["id"] || ""),
        name: s["name"],
        driver: provider,
        ip: ip,
        state: st(s["state"]),
        extra: s
      }
    end

    defp st("running"), do: :running
    defp st("starting"), do: :starting
    defp st("stopped"), do: :stopped
    defp st(_), do: :unknown
  end
end
