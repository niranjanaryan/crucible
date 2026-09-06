defmodule Mix.Tasks.Crucible.Install do
  @moduledoc "Build escript and install `crucible` for Linux, macOS, and Windows."
  use Mix.Task
  @shortdoc "Install the crucible CLI (all OS)"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")
    Mix.Task.run("escript.build")

    dest = Crucible.CLI.Paths.install_escript("crucible")
    Mix.shell().info("installed #{dest}")
    Mix.shell().info(path_hint())
  end

  defp path_hint do
    dir = Crucible.CLI.Paths.bin_dir()

    if Crucible.CLI.Paths.windows?() do
      "add #{dir} to PATH (Windows: System Properties → Environment Variables)"
    else
      "ensure #{dir} is on PATH"
    end
  end
end
