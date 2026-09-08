defmodule Crucible.Driver.Stacks.CloudInit do
  @moduledoc """
  Stacks-specific cloud-init templates for Crucible.

  Generates Ubuntu 24.04 cloud-init user-data that installs and configures
  Stacks nodes (signer, API, sBTC relay) on first boot.
  """

  @doc """
  Generate cloud-init for a Stacks signer node.

  Installs `stacks-node`, writes `stacks-node.toml`, and sets PoX-5 config.
  """
  def signer(env \\ %{}) do
    """
    #cloud-config
    package_update: true
    packages:
      - curl
      - jq
      - docker.io
    runcmd:
      - curl -fsSL https://download.stacks.co/stacks-node/install.sh | bash
      - |
        cat > /etc/stacks-node.toml << 'EOF'
        ${stacks_toml(env)}
        EOF
      - systemctl enable stacks-node
      - systemctl start stacks-node
    """
    |> String.replace("${stacks_toml(env)}", stacks_toml(env))
    |> String.trim()
  end

  @doc """
  Generate cloud-init for a Stacks API node.
  """
  def api_node(env \\ %{}) do
    """
    #cloud-config
    package_update: true
    packages:
      - curl
      - jq
      - docker.io
    runcmd:
      - curl -fsSL https://download.stacks.co/stacks-node/install.sh | bash
      - |
        cat > /etc/stacks-node.toml << 'EOF'
        ${stacks_toml(env)}
        EOF
      - systemctl enable stacks-node
      - systemctl start stacks-node
    """
    |> String.replace("${stacks_toml(env)}", stacks_toml(env))
    |> String.trim()
  end

  @doc """
  Generate cloud-init for an sBTC relay node.
  """
  def sbtc_relay(env \\ %{}) do
    """
    #cloud-config
    package_update: true
    packages:
      - curl
      - jq
      - docker.io
      - docker-compose
    runcmd:
      - curl -fsSL https://download.stacks.co/sbtc-relay/install.sh | bash
      - |
        cat > /etc/sbtc-relay.toml << 'EOF'
        ${sbtc_relay_toml(env)}
        EOF
      - systemctl enable sbtc-relay
      - systemctl start sbtc-relay
    """
    |> String.replace("${sbtc_relay_toml(env)}", sbtc_relay_toml(env))
    |> String.trim()
  end

  defp stacks_toml(env) do
    """
    [node]
    rpc_bind = "0.0.0.0:3999"
    p2p_bind = "0.0.0.0:20444"
    bootstrap_nodes = []
    pox_2_activation_height = #{env["POX_2_ACTIVATION_HEIGHT"] || 1000}

    [miner]
    # PoX-5 signer config
    first_phase = #{env["STACKS_FIRST_PHASE"] || "true"}
    second_phase = #{env["STACKS_SECOND_PHASE"] || "true"}
    """
    |> String.trim()
  end

  defp sbtc_relay_toml(env) do
    """
    [relay]
    bitcoin_rpc_url = "#{env["BTC_RPC_URL"] || "http://localhost:8332"}"
    stacks_rpc_url = "#{env["STACKS_RPC_URL"] || "http://localhost:3999"}"
    private_key = "#{env["RELAY_PRIVATE_KEY"] || ""}"

    [metrics]
    bind = "0.0.0.0:8080"
    """
    |> String.trim()
  end
end
