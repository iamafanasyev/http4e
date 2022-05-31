defmodule Coroutine do
  @type t(input, output) :: (input -> [yield: output, cont: nil | Coroutine.t(input, output)])

  @spec from(any()) :: Coroutine.t({}, any())
  def from(x) do
    fn {} -> [yield: x, cont: nil] end
  end
end
