defmodule Http4e.Server.GenTcpTest do
  use ExUnit.Case

  setup_all do
    %Http4e.Server.GenTcp{
      listen_port: 3000,
      response_body_stream_reader: %Http4e.BodyStream.Reader.Buffered{buffer_size_in_bytes: 1},
    }
    |> Http4e.Server.start(&handler/1)
    |> on_exit()
  end

  describe "HTTP/1.1 GenTcp webserver" do
    test "should be able to accept GET-request" do
      assert {
               :ok,
               {{'HTTP/1.1', 200, 'OK'}, _headers, 'pong'}
             } = :httpc.request("http://localhost:3000/ping")
    end

    test "should be able to accept POST-request" do
      short_article = '42'

      assert {
               :ok,
               {{'HTTP/1.1', 200, 'OK'}, _headers, ^short_article}
             } =
               :httpc.request(
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

      long_article = 'The Answer is 42'

      assert {
               :ok,
               {{'HTTP/1.1', 200, 'OK'}, _headers, ^long_article}
             } =
               :httpc.request(
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

  defp handler(assignments: %{}, request: %Http4e.Request{method: :GET, path: "/ping"}) do
    %Http4e.Response{
      body_stream: Coroutine.from("pong"),
      headers: %{
        "content-length" => 4,
        "content-type" => "text/plain",
      },
      status: Http4e.Response.Status.ok(),
    }
  end

  defp handler(
         assignments: %{},
         request: %Http4e.Request{method: :POST, path: "/short_article"} = request
       ) do
    article_review = Http4e.BodyStream.await(request.body_stream)

    %Http4e.Response{
      body_stream: Coroutine.from(article_review),
      headers: %{
        "content-length" => article_review |> String.length() |> to_string(),
        "content-type" => "text/plain",
      },
      status: Http4e.Response.Status.ok(),
    }
  end

  defp handler(
         assignments: %{},
         request: %Http4e.Request{method: :POST, path: "/long_article"} = request
       ) do
    %Http4e.Response{
      body_stream: simulate_request_downloading_and_response_streaming(request.body_stream, 200),
      headers: %{
        "content-type" => "text/plain",
      },
      status: Http4e.Response.Status.ok(),
    }
  end

  defp simulate_request_downloading_and_response_streaming(
         request_body_stream,
         download_delay_in_milliseconds
       ) do
    fn [body_part_size_in_bytes: body_part_size_in_bytes] ->
      :timer.sleep(download_delay_in_milliseconds)

      case request_body_stream.(body_part_size_in_bytes: body_part_size_in_bytes) do
        [yield: _request_body_part, continuation: nil] = last_chunk ->
          last_chunk

        [yield: request_body_part, continuation: rest_request_body_stream] ->
          [
            yield: request_body_part,
            continuation:
              simulate_request_downloading_and_response_streaming(
                rest_request_body_stream,
                download_delay_in_milliseconds
              ),
          ]
      end
    end
  end
end
