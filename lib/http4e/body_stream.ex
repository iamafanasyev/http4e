defmodule Http4e.BodyStream do
  @type t() :: Coroutine.t([body_part_size_in_bytes: non_neg_integer()], body_part :: binary())

  @default_body_part_size_in_bytes 8 * 1024
  @spec await(t(), body_part_size_in_bytes: non_neg_integer()) :: binary()
  def await(
        body_stream,
        [body_part_size_in_bytes: body_part_size_in_bytes] \\ [
          body_part_size_in_bytes: @default_body_part_size_in_bytes,
        ]
      ) do
    Coroutine.fold(
      body_stream,
      <<>>,
      [body_part_size_in_bytes: body_part_size_in_bytes],
      &<>/2
    )
  end

  @spec empty() :: t()
  def empty() do
    Coroutine.from("")
  end
end
