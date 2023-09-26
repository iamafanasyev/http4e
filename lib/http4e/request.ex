defmodule Http4e.Request do
  @type body_stream() :: Http4e.BodyStream.t()
  @type headers() :: %{(downcased_header_name :: String.t()) => header_value :: String.t()}
  @type method() :: :DELETE | :GET | :HEAD | :OPTIONS | :PATCH | :POST | :PUT | :TRACE
  @type path() :: String.t()
  @type query_parameters() :: %{String.t() => list(String.t())}
  @keys [
    :body_stream,
    :headers,
    :method,
    :path,
    :query_parameters,
  ]
  @enforce_keys @keys
  defstruct @keys
end
