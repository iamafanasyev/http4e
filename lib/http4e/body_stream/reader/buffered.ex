defmodule Http4e.BodyStream.Reader.Buffered do
  @type buffer_size_in_bytes() :: non_neg_integer()
  @keys [
    :buffer_size_in_bytes,
  ]
  @enforce_keys @keys
  defstruct @keys
end
