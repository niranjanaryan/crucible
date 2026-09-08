defmodule Crucible.Driver.REST.Codec.GCE do
  @moduledoc false
  alias Crucible.{CloudInit, Machine, Auth.GCP}

  def create(state, spec) do
    project = project(state)
    zone = zone(state, spec)
    name = spec[:name] || "crucible-#{System.unique_integer([:positive])}"
    size = spec[:size] || state.opts[:size] || "e2-micro"

    image =
      spec[:image] || state.opts[:image] || "projects/debian-cloud/global/images/family/debian-12"

    body = %{
      name: name,
      machineType: "zones/#{zone}/machineTypes/#{size}",
      disks: [
        %{
          boot: true,
          autoDelete: true,
          initializeParams: %{sourceImage: image}
        }
      ],
      networkInterfaces: [
        %{
          accessConfigs: [%{type: "ONE_TO_ONE_NAT", name: "External NAT"}]
        }
      ],
      metadata: %{
        items: [%{key: "user-data", value: CloudInit.from_env(spec[:env] || %{})}]
      }
    }

    {:post, "/projects/#{project}/zones/#{zone}/instances", body}
  end

  def get(state, %Machine{id: id, extra: extra}) do
    project = extra["project"] || extra[:project] || project(state)
    zone = extra["zone"] || extra[:zone] || zone(state, %{})
    op = extra["operation"] || extra[:operation]

    if is_binary(op) and op != "" do
      {:get, "/projects/#{project}/zones/#{zone}/operations/#{op}"}
    else
      {:get, "/projects/#{project}/zones/#{zone}/instances/#{id}"}
    end
  end

  def delete(state, %Machine{id: id, extra: extra}) do
    project = extra["project"] || extra[:project] || project(state)
    zone = extra["zone"] || extra[:zone] || zone(state, %{})
    {:delete, "/projects/#{project}/zones/#{zone}/instances/#{id}"}
  end

  def to_machine(body, provider) when is_map(body) do
    cond do
      body["kind"] == "compute#operation" ->
        %Machine{
          id: instance_id(body),
          name: instance_id(body),
          driver: provider,
          state: if(body["status"] == "DONE", do: :starting, else: :pending),
          extra: %{
            "operation" => if(body["status"] == "DONE", do: nil, else: body["name"]),
            "zone" => last_path(body["zone"]),
            "project" => project_from_link(body["targetLink"] || body["selfLink"] || "")
          }
        }

      true ->
        %Machine{
          id: body["name"] || "",
          name: body["name"],
          driver: provider,
          ip: nat_ip(body),
          state: st(body["status"]),
          extra: %{
            "zone" => last_path(body["zone"]),
            "project" => project_from_link(body["selfLink"] || "")
          }
        }
    end
  end

  defp project(state), do: GCP.project(state.opts) || state.opts[:project] || "local"
  defp zone(state, spec), do: spec[:region] || state.opts[:region] || "us-central1-a"

  defp instance_id(%{"targetLink" => link}) when is_binary(link), do: last_path(link)
  defp instance_id(%{"name" => name}), do: name
  defp instance_id(_), do: ""

  defp last_path(nil), do: nil
  defp last_path(link), do: link |> String.split("/") |> List.last()

  defp project_from_link(link) do
    case Regex.run(~r{/projects/([^/]+)/}, link) do
      [_, p] -> p
      _ -> nil
    end
  end

  defp nat_ip(inst) do
    inst
    |> Map.get("networkInterfaces", [])
    |> List.first()
    |> case do
      %{"accessConfigs" => [%{"natIP" => ip} | _]} -> ip
      _ -> nil
    end
  end

  defp st("RUNNING"), do: :running
  defp st("STAGING"), do: :starting
  defp st("PROVISIONING"), do: :starting
  defp st("TERMINATED"), do: :stopped
  defp st(_), do: :unknown
end
