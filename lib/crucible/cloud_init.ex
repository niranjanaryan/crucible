defmodule Crucible.CloudInit do
  @moduledoc "Turn spec env into cloud-init user_data for VM drivers."

  def from_env(env) when is_map(env) do
    exports =
      env
      |> Enum.map(fn {k, v} -> "export #{k}=#{inspect(to_string(v))}" end)
      |> Enum.join("\n")

    """
    #cloud-config
    runcmd:
      - bash -lc #{inspect("set -a\n#{exports}\n")}
    write_files:
      - path: /etc/crucible.env
        permissions: '0600'
        content: |
    #{indent(exports, 6)}
    """
  end

  defp indent(text, n) do
    pad = String.duplicate(" ", n)

    text
    |> String.split("\n")
    |> Enum.map_join("\n", &(pad <> &1))
  end
end
