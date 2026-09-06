defmodule Mix.Tasks.Crucible.Providers do
  @shortdoc "List Crucible cloud drivers"
  @moduledoc "mix crucible.providers [--implemented] [--kind rest|wrap|builtin|catalog] [--json]"
  use Mix.Task

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Crucible.run(["providers" | args])
end
