defmodule Crucible.Size do
  @moduledoc "Libcloud `NodeSize`: flavor id, ram (MB), cpu, disk (GB)."
  defstruct [:id, :name, ram: nil, cpu: nil, disk: nil, price: nil, extra: %{}]
end
