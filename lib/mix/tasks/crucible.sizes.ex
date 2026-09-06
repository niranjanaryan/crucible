defmodule Mix.Tasks.Crucible.Sizes do
  @shortdoc "List sizes for a driver"
  @moduledoc "mix crucible.sizes --driver NAME [--json]"
  use Mix.Task

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Crucible.run(["sizes" | args])
end
