defmodule Mix.Tasks.Crucible.Describe do
  @shortdoc "Describe a machine"
  @moduledoc "mix crucible.describe --driver NAME --id ID [--json]"
  use Mix.Task

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Crucible.run(["describe" | args])
end
