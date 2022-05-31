defmodule Http4e.Server.FilterTest do
  use ExUnit.Case

  defmodule Handler do
    use Http4e.Handler.Behaviour

    @impl Http4e.Handler.Behaviour
    def handle(assignments: %{filter_power: filter_power}, request: _) when filter_power >= 1 do
      body =
        to_string(filter_power)
      %{
        body_stream: Coroutine.from(body),
        headers: %{
          "Content-Length" => String.length(body),
          "Content-Type" => "text/plain",
        },
        status: Http4e.Response.Status.ok(),
      }
    end
  end

  defmodule Power2Filter do
    use Http4e.Filter.Behaviour

    @impl Http4e.Filter.Behaviour
    @spec filter(
            Http4e.Handler.Behaviour.with_assignments(%{optional(:filter_power) => pos_integer()})
          ) :: Http4e.Handler.Behaviour.with_assignments(%{filter_power: pos_integer()})
    def filter({:handler, handle}) when is_function(handle) do
      {
        :handler,
        fn
          [assignments: %{filter_power: filter_power} = assignments, request: %{} = request] when filter_power >= 1 ->
            handle.(assignments: Map.put(assignments, :filter_power, Integer.pow(filter_power, 2)), request: request)

          [assignments: %{} = assignments, request: %{} = request] ->
            handle.(assignments: Map.put(assignments, :filter_power, 2), request: request)
        end
      }
    end
  end

  defmodule Power3Filter do
    use Http4e.Filter.Behaviour

    @impl Http4e.Filter.Behaviour
    @spec filter(
            Http4e.Handler.Behaviour.with_assignments(%{optional(:filter_power) => pos_integer()})
          ) :: Http4e.Handler.Behaviour.with_assignments(%{filter_power: pos_integer()})
    def filter({:handler, handle}) when is_function(handle) do
      {
        :handler,
        fn
          [assignments: %{filter_power: filter_power} = assignments, request: %{} = request] when filter_power >= 1 ->
            handle.(assignments: Map.put(assignments, :filter_power, Integer.pow(filter_power, 3)), request: request)

          [assignments: %{} = assignments, request: %{} = request] ->
            handle.(assignments: Map.put(assignments, :filter_power, 3), request: request)
        end
      }
    end
  end

  describe "Filter behaviour" do
    test "should respect chaining" do
      {:handler, filtered_handle} =
        Handler.as_handler()
        |> Power2Filter.filter()
        |> Power3Filter.filter()
      %{body_stream: response_body_stream} =
        filtered_handle.(assignments: %{}, request: %{})
      assert [yield: "9", cont: :nil] = response_body_stream.({}),
             "Expected filter application from the last piped one up to the first"

      {:handler, filtered_handle} =
        Handler.as_handler()
        |> Power3Filter.filter()
        |> Power2Filter.filter()
      %{body_stream: response_body_stream} =
        filtered_handle.(assignments: %{}, request: %{})
      assert [yield: "8", cont: :nil] = response_body_stream.({}),
             "Expected filter application from the last piped one up to the first"
    end
  end
end
