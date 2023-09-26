defimpl Http4e.BodyStream.Reader, for: Http4e.BodyStream.Reader.Buffered do
  @spec from(
          %Http4e.BodyStream.Reader.Buffered{},
          Http4e.BodyStream.t()
        ) :: Http4e.BodyStream.Reader.stream(body_part :: binary())
  def from(buffered_body_stream_reader, body_stream) do
    Stream.unfold(
      body_stream,
      fn
        nil ->
          nil

        stream ->
          [yield: body_part, cont: suspension] =
            stream.(body_part_size_in_bytes: buffered_body_stream_reader.buffer_size_in_bytes)

          {body_part, suspension}
      end
    )
  end
end
