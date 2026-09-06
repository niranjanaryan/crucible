defmodule Crucible.Machine do
  @moduledoc """
  Libcloud `Node`: id, name, state, addresses. The driver owns HTTP.

  `ip` is the public address used for `Node.connect` when not using Iroh.
  """

  @enforce_keys [:id, :driver]
  defstruct [
    :id,
    :driver,
    :name,
    :ip,
    :ipv6,
    :private_ip,
    :node,
    :pid,
    state: :pending,
    extra: %{},
    meta: %{}
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          driver: atom(),
          name: String.t() | nil,
          ip: String.t() | nil,
          ipv6: String.t() | nil,
          private_ip: String.t() | nil,
          node: node() | nil,
          pid: pid() | nil,
          state: atom(),
          extra: map(),
          meta: map()
        }
end
