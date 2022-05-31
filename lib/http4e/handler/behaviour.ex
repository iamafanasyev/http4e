defmodule Http4e.Handler.Behaviour do
  @type with_assignments(a) ::
          {:handler, ([assignments: a, request: Http4e.Request.t()] -> Http4e.Response.t())}

  @type t :: with_assignments(%{atom() => String.t()})

  @callback handle(assignments: %{atom() => String.t()}, request: Http4e.Request.t()) ::
              Http4e.Response.t()

  defmacro __using__([]) do
    quote do
      @behaviour Http4e.Handler.Behaviour

      @spec as_handler() :: Http4e.Handler.Behaviour.t()
      def as_handler() do
        {:handler, &handle/1}
      end
    end
  end
end
