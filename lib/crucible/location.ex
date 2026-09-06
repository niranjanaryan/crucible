defmodule Crucible.Location do
  @moduledoc "Libcloud `NodeLocation`: region / availability zone."
  defstruct [:id, :name, country: nil, extra: %{}]
end
