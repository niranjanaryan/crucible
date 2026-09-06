defmodule Mix.Tasks.Crucible.Sizes do
  @shortdoc "List instance sizes"
  @moduledoc "mix crucible.sizes --driver NAME [--json]"
  use Mix.Task

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Crucible.run(["sizes" | args])
end
