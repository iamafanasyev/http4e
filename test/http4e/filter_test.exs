defmodule Http4e.FilterTest do
  use ExUnit.Case

  describe "Filter" do
    test "should respect chaining" do
      yields_9 =
        (&handler(&1))
        |> power2_filter()
        |> power3_filter()

      %Http4e.Response{body_stream: response_body_stream} =
        yields_9.(assignments: %{}, request: request())

      assert "9" = Http4e.BodyStream.await(response_body_stream),
             "Expected filter application from the last piped one up to the first"

      yields_8 =
        (&handler(&1))
        |> power3_filter()
        |> power2_filter()

      %Http4e.Response{body_stream: response_body_stream} =
        yields_8.(assignments: %{}, request: request())

      assert "8" = Http4e.BodyStream.await(response_body_stream),
             "Expected filter application from the last piped one up to the first"
    end
  end

  defp handler(assignments: %{filter_power: filter_power}, request: %Http4e.Request{}) do
    body = to_string(filter_power)

    %Http4e.Response{
      body_stream: Coroutine.from(body),
      headers: %{
        "Content-Length" => String.length(body),
        "Content-Type" => "text/plain",
      },
      status: Http4e.Response.Status.ok(),
    }
  end

  @spec power2_filter(Http4e.Handler.t()) :: Http4e.Handler.t()
  defp power2_filter(handler) do
    fn
      [
        assignments: %{filter_power: filter_power} = assignments,
        request: %Http4e.Request{} = request,
      ] ->
        handler.(
          assignments: Map.put(assignments, :filter_power, Integer.pow(filter_power, 2)),
          request: request
        )

      [assignments: %{} = assignments, request: %Http4e.Request{} = request] ->
        handler.(assignments: Map.put(assignments, :filter_power, 2), request: request)
    end
  end

  @spec power3_filter(Http4e.Handler.t()) :: Http4e.Handler.t()
  defp power3_filter(handler) do
    fn
      [
        assignments: %{filter_power: filter_power} = assignments,
        request: %Http4e.Request{} = request,
      ] ->
        handler.(
          assignments: Map.put(assignments, :filter_power, Integer.pow(filter_power, 3)),
          request: request
        )

      [assignments: %{} = assignments, request: %Http4e.Request{} = request] ->
        handler.(assignments: Map.put(assignments, :filter_power, 3), request: request)
    end
  end

  @spec request() :: %Http4e.Request{}
  defp request() do
    %Http4e.Request{
      body_stream: Http4e.BodyStream.empty(),
      headers: %{},
      method: :GET,
      path: "/",
      query_parameters: %{},
    }
  end
end
