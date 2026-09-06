defmodule Mix.Tasks.Crucible do
  @moduledoc "Crucible CLI. Same as the `crucible` escript."
  use Mix.Task
  @shortdoc "crucible ls|boot|rm|describe|sizes|http|version"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    Crucible.CLI.main(args, halt: false)
  end
end
