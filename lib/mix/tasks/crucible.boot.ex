defmodule Mix.Tasks.Crucible.Boot do
  @shortdoc "Boot a machine"
  @moduledoc "mix crucible.boot --driver NAME [--name N] [--image I] [--size S] [--region R] [--token T] [--env K=V] [--json]"
  use Mix.Task

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Crucible.run(["boot" | args])
end
