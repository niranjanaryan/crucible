defmodule Mix.Tasks.Crucible.Install do
  @moduledoc "Build the escript and install `crucible` to ~/.local/bin."
  use Mix.Task
  @shortdoc "Install the crucible CLI"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")
    Mix.Task.run("escript.build")

    bin_dir = Path.expand("~/.local/bin")
    File.mkdir_p!(bin_dir)

    escript = Path.join(File.cwd!(), "crucible")
    dest = Path.join(bin_dir, "crucible")
    File.cp!(escript, dest)
    File.chmod!(dest, 0o755)

    Mix.shell().info("installed #{dest}")
    Mix.shell().info("ensure #{bin_dir} is on PATH")
  end
end
