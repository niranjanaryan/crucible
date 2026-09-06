defmodule Crucible.Driver.Docker do
  @moduledoc "Docker Engine CLI. Set `image:` on init or spec."
  @behaviour Crucible.Driver

  alias Crucible.Machine

  @impl true
  def init(opts), do: {:ok, %{opts: opts}}

  @impl true
  def boot(state, spec) do
    image = spec[:image] || state.opts[:image]

    cond do
      is_nil(System.find_executable("docker")) ->
        {:error, {:driver_unavailable, :docker}}

      not is_binary(image) ->
        {:error, :docker_image_required}

      true ->
        env = spec[:env] || %{}

        args =
          ["run", "-d", "--rm"] ++
            Enum.flat_map(env, fn {k, v} -> ["-e", "#{k}=#{v}"] end) ++
            [image]

        case System.cmd("docker", args, stderr_to_stdout: true) do
          {id, 0} ->
            cid = String.trim(id)

            {:ok, %Machine{id: cid, driver: :docker, meta: %{image: image}}, state}

          {out, code} ->
            {:error, {:docker_run_failed, code, String.slice(out, 0, 400)}}
        end
    end
  end

  @impl true
  def await(state, machine, _timeout), do: {:ok, machine, state}

  @impl true
  def shutdown(_state, %Machine{id: id, driver: :docker}) do
    _ = System.cmd("docker", ["rm", "-f", id], stderr_to_stdout: true)
    :ok
  end

  @impl true
  def describe(_state, machine), do: {:ok, Map.from_struct(machine)}
end
