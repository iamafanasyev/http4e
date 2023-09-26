defmodule Coroutine do
  @type t(input, output) :: (input -> suspension(input, output))

  @type suspension(input, output) :: [yield: output, cont: nil | Coroutine.t(input, output)]

  @spec fold(t(input, output), acc, input, (acc, output -> acc)) :: acc
        when acc: any(), input: any(), output: any()
  def fold(coroutine, acc, input, combine) do
    case coroutine.(input) do
      [yield: output, cont: nil] ->
        combine.(acc, output)

      [yield: output, cont: suspension] ->
        fold(suspension, combine.(acc, output), input, combine)
    end
  end

  @spec from(a) :: Coroutine.t(no_args :: any(), a) when a: any()
  def from(x) do
    fn _ -> [yield: x, cont: nil] end
  end
end
