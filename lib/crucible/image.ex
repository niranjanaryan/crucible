defmodule Crucible.Image do
  @moduledoc "Libcloud `NodeImage`: AMI, snapshot, or container image."
  defstruct [:id, :name, extra: %{}]
end
