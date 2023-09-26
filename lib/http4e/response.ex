defmodule Http4e.Response do
  @type body_stream() :: Http4e.BodyStream.t()
  @type headers() :: %{(downcased_header_name :: String.t()) => header_value :: String.t()}
  @type status() :: %Http4e.Response.Status{}
  @keys [
    :body_stream,
    :headers,
    :status,
  ]
  @enforce_keys @keys
  defstruct @keys
end
