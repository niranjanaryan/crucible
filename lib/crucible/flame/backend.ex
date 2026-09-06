defmodule Crucible.FLAME.Backend do
  @moduledoc """
  `FLAME.Backend` that boots via `Crucible` drivers.

      config :flame, :backend, {Crucible.FLAME.Backend,
        driver: :local}
      # driver: :docker | :fly | :k8s | :ec2 | Crucible.Driver.Hetzner
  """

  def init(opts) when is_list(opts) do
    with {:ok, crucible} <- Crucible.init(opts) do
      {:ok,
       %{
         crucible: crucible,
         opts: opts,
         machine: nil,
         runner: nil
       }}
    end
  end

  def remote_boot(state) do
    spec = %{env: flame_env(state.opts)}

    with {:ok, machine, crucible} <- Crucible.boot(state.crucible, spec),
         {:ok, machine, crucible} <- Crucible.await(crucible, machine) do
      runner = machine.pid || self()
      {:ok, runner, %{state | crucible: crucible, machine: machine, runner: runner}}
    end
  end

  def remote_spawn_monitor(%{machine: %Crucible.Machine{driver: :local} = m} = _state, func)
      when is_function(func, 0) do
    Crucible.Driver.Local.spawn_fun(m, func)
  end

  def remote_spawn_monitor(%{runner: runner}, func)
      when is_pid(runner) and is_function(func, 0) do
    {pid, ref} = spawn_monitor(func)
    {:ok, {pid, ref}}
  end

  def remote_spawn_monitor(state, func) when is_function(func, 0) do
    with {:ok, _term, state2} <- remote_boot(state) do
      remote_spawn_monitor(state2, func)
    end
  end

  def system_shutdown, do: :ok

  def handle_info(_msg, state), do: {:noreply, state}

  defp flame_env(opts) do
    Map.merge(Keyword.get(opts, :env, %{}), %{
      "CRUCIBLE_DRIVER" => to_string(Keyword.get(opts, :driver, :local))
    })
  end
end
