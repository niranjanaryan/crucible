defmodule Mix.Tasks.Crucible.Install do
  @moduledoc "Install crucible: Burrito single binary if possible, else escript."
  use Mix.Task
  @shortdoc "Install the crucible CLI (single binary or escript)"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")

    case maybe_burrito() do
      {:ok, src} ->
        dest = Crucible.CLI.Paths.install_bin(src, "crucible")
        Mix.shell().info("installed single binary #{dest}")

      :error ->
        Mix.Task.run("escript.build")
        dest = Crucible.CLI.Paths.install_escript("crucible")
        Mix.shell().info("installed escript #{dest} (needs escript on PATH)")
        Mix.shell().info("for a single binary: zig 0.15 + xz, then mix crucible.binary")
    end

    Mix.shell().info("bin dir #{Crucible.CLI.Paths.bin_dir()}")
  end

  defp maybe_burrito do
    Mix.Task.run("crucible.binary")

    case Path.wildcard("burrito_out/crucible_*") do
      [f | _] -> {:ok, f}
      _ -> :error
    end
  rescue
    e ->
      Mix.shell().error("burrito: #{Exception.message(e)}")
      :error
  end
end
