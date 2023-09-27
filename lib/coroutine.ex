defmodule Coroutine do
  @type t(input, output) :: (input -> suspension(input, output))

  @type suspension(input, output) :: [
          yield: output,
          continuation: nil | Coroutine.t(input, output),
        ]

  @spec fold(t(input, output), acc, input, (acc, output -> acc)) :: acc
        when acc: any(), input: any(), output: any()
  def fold(coroutine, acc, input, combine) do
    case coroutine.(input) do
      [yield: output, continuation: nil] ->
        combine.(acc, output)

      [yield: output, continuation: cont] ->
        fold(cont, combine.(acc, output), input, combine)
    end
  end

  @spec from(a) :: Coroutine.t(no_args :: any(), a) when a: any()
  def from(a) do
    fn _no_args -> [yield: a, continuation: nil] end
  end
end
