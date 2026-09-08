defmodule Crucible.Driver.Stacks.HealthCheck do
  @moduledoc """
  Health checks for Stacks nodes provisioned by Crucible.

  Polls Stacks RPC endpoints until the node is synced and ready.
  """

  @timeout 2_000

  @doc """
  Check if a Stacks node is healthy and synced.

  Returns `:ok` if the node responds to `/v2/info` with `{:ok, true}`,
  `:waiting` if the node is still starting, or `{:error, reason}` on failure.
  """
  def check(ip, port \\ 3999) when is_binary(ip) do
    url = "http://#{ip}:#{port}/v2/info"

    case :httpc.request(:get, {url, []}, [], timeout: @timeout) do
      {:ok, {{_, 200, _}, _, body}} ->
        case Jason.decode(body) do
          {:ok, %{"sync" => %{"is_node_synced" => true}}} -> :ok
          {:ok, _} -> :waiting
          {:error, _} -> :waiting
        end

      {:ok, {{_, status, _}, _, _}} when status in [404, 503] ->
        :waiting

      {:error, :timeout} ->
        :waiting

      {:error, _} ->
        {:error, :health_check_failed}
    end
  rescue
    _ -> :waiting
  end

  @doc """
  Poll a Stacks node until it is synced.

  Returns `{:ok, ip}` if the node becomes healthy within `timeout_ms`,
  or `{:error, :timeout}` if it doesn't.
  """
  def await(ip, timeout_ms \\ 300_000, port \\ 3999) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    do_await(ip, port, deadline)
  end

  defp do_await(ip, port, deadline) do
    if System.monotonic_time(:millisecond) > deadline do
      {:error, :timeout}
    else
      case check(ip, port) do
        :ok -> {:ok, ip}
        :waiting ->
          Process.sleep(200)
          do_await(ip, port, deadline)
        {:error, _} = err ->
          Process.sleep(200)
          do_await(ip, port, deadline)
      end
    end
  end
end
