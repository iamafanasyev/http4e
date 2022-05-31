defmodule Http4e.Server.GenTcpTest do
  use ExUnit.Case

  defmodule Handler do
    use Http4e.Handler.Behaviour

    @impl Http4e.Handler.Behaviour
    def handle(assignments: %{}, request: %{method: :GET, path: "/ping"}) do
      %{
        body_stream: Coroutine.from("pong"),
        headers: %{
          "Content-Length" => 4,
          "Content-Type" => "text/plain",
        },
        status: Http4e.Response.Status.ok(),
      }
    end

    def handle(assignments: %{}, request: %{await_body: await_body, method: :POST, path: "/short_article"}) do
      article_review =
        await_body.()
      %{
        body_stream: Coroutine.from(article_review),
        headers: %{
          "Content-Length" => String.length(article_review),
          "Content-Type" => "text/plain",
        },
        status: Http4e.Response.Status.ok(),
      }
    end

    def handle(assignments: %{}, request: %{body_stream: body_stream, method: :POST, path: "/long_article"}) do
      %{
        body_stream: simulate_downloading_and_stream_it(request_body_stream: body_stream, chunk_byte_size: 1),
        headers: %{
          "Content-Type" => "text/plain",
        },
        status: Http4e.Response.Status.ok(),
      }
    end

    @spec simulate_downloading_and_stream_it(
            [
              request_body_stream: Http4e.Request.body_stream(),
              chunk_byte_size: pos_integer(),
            ]
          ) :: Http4e.Response.body_stream()
    defp simulate_downloading_and_stream_it(
           [
             request_body_stream: request_body_stream,
             chunk_byte_size: chunk_byte_size,
           ]
         ) do
      fn {} ->
        :timer.sleep(200)
        [yield: request_body_part, cont: rest_request_body_stream] =
          request_body_stream.(body_part_size_in_bytes: chunk_byte_size)
        IO.write(request_body_part)
        [
          yield: request_body_part,
          cont: case rest_request_body_stream do
            :nil ->
              :nil

            _ ->
              simulate_downloading_and_stream_it(
                request_body_stream: rest_request_body_stream,
                chunk_byte_size: chunk_byte_size
              )
          end,
        ]
      end
    end
  end

  setup_all do
    {:ok, shutdown_server} =
      Http4e.Server.GenTcp.start(handler: Handler.as_handler(), listen_port: 3000)
    on_exit(shutdown_server)
  end

  describe "GenTcp-backed webserver" do
    test "should be able to accept GET-request" do
      assert {
               :ok,
               {{'HTTP/1.1', 200, 'OK'}, _headers, 'pong'}
             } = :httpc.request("http://localhost:3000/ping")
    end

    test "should be able to accept POST-request" do
      short_article =
        '42'
      assert {
               :ok,
               {{'HTTP/1.1', 200, 'OK'}, _headers, ^short_article}
             } = :httpc.request(
               :post,
               {
                 'http://localhost:3000/short_article',
                 [],
                 'text/plain',
                 short_article
               },
               [],
               []
             )

      long_article =
        'The Answer is 42'
      assert {
               :ok,
               {{'HTTP/1.1', 200, 'OK'}, _headers, ^long_article}
             } = :httpc.request(
               :post,
               {
                 'http://localhost:3000/long_article',
                 [],
                 'text/plain',
                 long_article
               },
               [],
               []
             )
    end
  end
end
