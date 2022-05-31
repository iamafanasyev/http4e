defmodule Http4e.Filter.Behaviour do
  @type t :: {:filter, (Http4e.Handler.Behaviour.t() -> Http4e.Handler.Behaviour.t())}

  @callback filter(Http4e.Handler.Behaviour.t()) :: Http4e.Handler.Behaviour.t()

  defmacro __using__([]) do
    quote do
      @behaviour Http4e.Filter.Behaviour

      @spec as_filter() :: Http4e.Filter.Behaviour.t()
      def as_filter() do
        {:filter, &filter/1}
      end
    end
  end
end
