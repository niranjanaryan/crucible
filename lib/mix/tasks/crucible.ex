defmodule Mix.Tasks.Crucible do
  @moduledoc "Crucible CLI. Same as the standalone `crucible` escript."
  use Mix.Task
  @shortdoc "crucible ls|boot|rm|describe|sizes|http|version"

  @impl Mix.Task
  def run(args) do
    Crucible.CLI.main(args, halt: false)
  end
end
