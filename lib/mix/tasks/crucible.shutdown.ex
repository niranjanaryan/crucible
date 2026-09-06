defmodule Mix.Tasks.Crucible.Shutdown do
  @shortdoc "Destroy a machine"
  @moduledoc "mix crucible.shutdown --driver NAME --id ID"
  use Mix.Task

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Crucible.run(["shutdown" | args])
end
