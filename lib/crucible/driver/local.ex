defmodule Crucible.Driver.Local do
  @moduledoc "In-process machine (FLAME.LocalBackend equivalent)."
  @behaviour Crucible.Driver

  alias Crucible.Machine

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def boot(state, _spec) do
    parent = self()

    {:ok, pid} =
      Task.start_link(fn ->
        Process.flag(:trap_exit, true)

        receive do
          {:boot, caller} ->
            send(caller, {:booted, self()})
            loop(parent)
        end
      end)

    send(pid, {:boot, self()})

    receive do
      {:booted, runner} ->
        machine = %Machine{
          id: "local-#{System.unique_integer([:positive])}",
          driver: :local,
          node: Node.self(),
          pid: runner,
          state: :running,
          ip: "127.0.0.1"
        }

        {:ok, machine, Map.put(state, :runner, runner)}
    after
      5_000 -> {:error, :boot_timeout}
    end
  end

  @impl true
  def await(state, machine, _timeout), do: {:ok, machine, state}

  @impl true
  def shutdown(_state, %Machine{pid: pid}) when is_pid(pid) do
    Process.exit(pid, :shutdown)
    :ok
  end

  def shutdown(_state, _), do: :ok

  @impl true
  def describe(_state, machine), do: {:ok, Map.from_struct(machine)}

  def spawn_fun(%Machine{pid: pid}, func) when is_pid(pid) and is_function(func, 0) do
    req = make_ref()
    send(pid, {:spawn, self(), req, func})

    receive do
      {:spawned, ^req, child} ->
        {:ok, {child, Process.monitor(child)}}
    after
      5_000 -> {:error, :spawn_timeout}
    end
  end

  defp loop(parent) do
    receive do
      {:spawn, from, ref, func} ->
        {pid, _} = spawn_monitor(func)
        send(from, {:spawned, ref, pid})
        loop(parent)

      {:EXIT, ^parent, reason} ->
        exit(reason)

      _ ->
        loop(parent)
    end
  end
end
