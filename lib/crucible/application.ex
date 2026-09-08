defmodule Crucible.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    maybe_cli()
    Supervisor.start_link([], strategy: :one_for_one, name: Crucible.Supervisor)
  end

  defp maybe_cli do
    if System.get_env("RELEASE_NAME") == "crucible" do
      args = :init.get_plain_arguments() |> Enum.map(&List.to_string/1)
      Crucible.CLI.main(args, halt: true)
    end
  end
end
