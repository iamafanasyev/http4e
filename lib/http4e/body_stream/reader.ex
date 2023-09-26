defprotocol Http4e.BodyStream.Reader do
  @type t() :: any()

  @type stream(_a) :: Enumerable.t()

  @spec from(t(), Http4e.BodyStream.t()) :: stream(body_part :: binary())
  def from(body_stream_reader, response_body_stream)
end
