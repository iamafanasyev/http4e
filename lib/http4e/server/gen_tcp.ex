defmodule Http4e.Server.GenTcp do
  @type listen_port() :: port()
  @type response_body_stream_reader :: Http4e.BodyStream.Reader.t()
  @keys [
    :listen_port,
    :response_body_stream_reader,
  ]
  @enforce_keys @keys
  defstruct @keys
end
