defmodule Crucible.CLI.Paths do
  @moduledoc false

  def windows?, do: match?({:win32, _}, :os.type())

  def bin_dir do
    System.get_env("ELIXCODER_BIN") || System.get_env("CRUCIBLE_BIN") || default_bin()
  end

  def install_escript(name) when is_binary(name) do
    dest_dir = bin_dir()
    File.mkdir_p!(dest_dir)
    src = Path.join(File.cwd!(), name)

    unless File.exists?(src) do
      raise ArgumentError, "escript not found at #{src}; run mix escript.build"
    end

    dest = Path.join(dest_dir, name)
    File.cp!(src, dest)
    unless windows?(), do: File.chmod!(dest, 0o755)

    if windows?() do
      File.write!(dest <> ".bat", "@echo off\r\nescript.exe \"%~dpn0\" %*\r\n")
    end

    dest
  end

  defp default_bin do
    if windows?(),
      do: Path.join(local_app_data(), "elixcoder/bin"),
      else: Path.expand("~/.local/bin")
  end

  defp local_app_data do
    System.get_env("LOCALAPPDATA") ||
      Path.join(System.get_env("USERPROFILE") || Path.expand("~"), "AppData/Local")
  end
end
