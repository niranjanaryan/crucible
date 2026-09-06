defmodule Mix.Tasks.Crucible.Http do
  @shortdoc "Print HTTP client (gale or req)"
  @moduledoc "mix crucible.http"
  use Mix.Task

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Crucible.run(["http" | args])
end
