defmodule Crucible.NodeState do
  @moduledoc """
  Libcloud `NodeState` subset.

  RUNNING, STARTING, PENDING, REBOOTING, STOPPING, STOPPED,
  TERMINATED, ERROR, UNKNOWN, SUSPENDED.
  """

  @states [
    :running,
    :starting,
    :pending,
    :rebooting,
    :stopping,
    :stopped,
    :terminated,
    :error,
    :unknown,
    :suspended
  ]

  def list, do: @states

  def running?(state), do: state == :running
end
