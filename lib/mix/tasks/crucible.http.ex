defmodule Mix.Tasks.Crucible.Http do
  @shortdoc "Print which HTTP client Crucible will use"
  @moduledoc "mix crucible.http"
  use Mix.Task

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Crucible.run(["http" | args])
end
