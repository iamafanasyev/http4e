defmodule Http4e.Response.Status do
  @type code() :: non_neg_integer()
  @type reason() :: String.t()
  @keys [
    :code,
    :reason,
  ]
  @enforce_keys @keys
  defstruct @keys

  @spec ok() :: %__MODULE__{}
  def ok() do
    %__MODULE__{code: 200, reason: "OK"}
  end

  @spec not_found() :: %__MODULE__{}
  def not_found() do
    %__MODULE__{code: 404, reason: "Not Found"}
  end
end
