defmodule Http4e.Server.GenTcp do
  @behaviour Http4e.Server.Behaviour

  @impl Http4e.Server.Behaviour
  @spec start(
          handler: Http4e.Handler.Behaviour.t(),
          listen_port: non_neg_integer()
        ) :: {:ok, shutdown_server :: (-> :ok)}
  def start(
        handler: {:handler, handle} = handler,
        listen_port: listen_port
      ) when is_function(handle) and listen_port >= 0 do
    {:ok, listen_socket} =
      :gen_tcp.listen(
        listen_port,
        # https://www.erlang.org/doc/man/inet.html#setopts-2
        active: false,
        mode: :binary,
        packet: :http_bin
      )

    Task.start_link(__MODULE__, :handle_incoming_connection_request, [listen_socket, handler])

    {:ok, fn -> :gen_tcp.close(listen_socket) end}
  end

  @http_1_1_line_ending "\r\n"
  @http_1_1_protocol "HTTP/1.1"
  @spec handle_incoming_connection_request(:gen_tcp.socket(), Http4e.Handler.Behaviour.t()) :: :ok
  def handle_incoming_connection_request(listen_socket, {:handler, handle} = handler) when is_function(handle) do
    # Wait for connection request
    {:ok, incoming_connection_request_socket} =
      :gen_tcp.accept(listen_socket, :infinity)
    # Request handler description
    request_handler =
      Stream.resource(
        fn ->
          incoming_connection_request_socket
        end,
        fn request_socket ->
          %{
            body_stream: body_stream,
            headers: headers,
            status: [code: code, reason: reason],
          } =
            handle.(assignments: %{}, request: receive_request(request_socket))

          # https://www.w3.org/Protocols/rfc2616/rfc2616-sec6.html
          response_first_line =
            "#{@http_1_1_protocol} #{code} #{reason}"
          response_header_lines =
            headers
            |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
          response_metadata_lines =
            [response_first_line | response_header_lines]
          request_socket
          |> :gen_tcp.send(
               "#{response_metadata_lines |> Enum.join(@http_1_1_line_ending)}#{@http_1_1_line_ending}#{@http_1_1_line_ending}"
             )

          :inet.setopts(incoming_connection_request_socket, packet: :http_bin)
          request_socket
          |> stream(body_stream)

          {:halt, request_socket}
        end,
        fn request_socket ->
          :gen_tcp.close(request_socket)
        end
      )
    # Run request handler asynchronously
    Task.start(
      fn ->
        Stream.run(request_handler)
      end
    )

    # Do it again
    handle_incoming_connection_request(listen_socket, handler)
  end

  @spec receive_request(
          :gen_tcp.socket(),
          already_revealed_request_metadata :: %{atom() => any()}
        ) :: Http4e.Request.t()
  defp receive_request(
         incoming_connection_request_socket,
         %{headers: %{} = headers} = request \\ %{headers: %{}}
       ) do
    case :gen_tcp.recv(incoming_connection_request_socket, 0) do
      {:ok, {:http_request, method, {:abs_path, abs_path}, _}}
      when method in [:DELETE, :GET, :HEAD, :OPTIONS, :PATCH, :POST, :PUT, :TRACE] ->
        [path | _] =
          abs_path
          |> String.split("?", parts: 2)
        receive_request(
          incoming_connection_request_socket,
          %{
            headers: %{},
            method: method,
            path: path,
            query_parameters: parse_query_parameters(abs_path),
          }
        )

      {:ok, {:http_header, _header_value_length, _header_key_string_or_atom, header_key, header_value}}
      when is_binary(header_key) and is_binary(header_value) ->
        receive_request(
          incoming_connection_request_socket,
          request |> Map.put(:headers, headers |> Map.put(String.downcase(header_key), header_value))
        )

      {:ok, :http_eoh} ->
        case request do
          %{method: method_without_body} when method_without_body in [:DELETE, :GET, :HEAD, :OPTIONS, :TRACE] ->
            request

          %{
            headers: %{
              "content-length" => content_length,
            },
            method: method_with_body,
          } when method_with_body in [:PATCH, :POST, :PUT] ->
            request
            |> Map.put(
                 :await_body,
                 fn ->
                   :inet.setopts(incoming_connection_request_socket, packet: :raw)
                   {:ok, <<_ :: binary()>> = body} =
                     :gen_tcp.recv(incoming_connection_request_socket, String.to_integer(content_length))
                   body
                 end
               )
            |> Map.put(
                 :body_stream,
                 build_body_stream(incoming_connection_request_socket, String.to_integer(content_length))
               )
        end
    end
  end

  @spec build_body_stream(
          :gen_tcp.socket(),
          remaining_bytes_number :: non_neg_integer()
        ) :: Http4e.Request.body_stream()
  defp build_body_stream(incoming_connection_request_socket, remaining_bytes_number) do
    fn [body_part_size_in_bytes: body_part_size_in_bytes] when body_part_size_in_bytes >= 0 ->
      :inet.setopts(incoming_connection_request_socket, packet: :raw)
      bytes_number =
        min(body_part_size_in_bytes, remaining_bytes_number)
      case :gen_tcp.recv(incoming_connection_request_socket, bytes_number) do
        {:ok, request_body_part} when is_binary(request_body_part) ->
          [
            yield: request_body_part,
            cont: if remaining_bytes_number - bytes_number > 0 do
              build_body_stream(incoming_connection_request_socket, remaining_bytes_number - bytes_number)
            else
              :nil
            end,
          ]
      end
    end
  end

  @spec parse_query_parameters(
          uri :: String.t()
        ) :: %{query_parameter_name :: String.t() => query_parameter_value :: String.t()}
  defp parse_query_parameters(uri) when is_binary(uri) do
    case String.split(uri, "?") do
      [_uri] ->
        %{}

      [_, encoded_query_parameters] ->
        encoded_query_parameters
        |> String.split("&")
        |> Enum.map(
             fn encoded_query_parameter ->
               encoded_query_parameter
               |> String.split("=")
               |> case do
                    [query_parameter_name] ->
                      {query_parameter_name, ""}

                    [query_parameter_name, query_parameter_value] ->
                      {query_parameter_name, query_parameter_value}
                  end
             end
           )
        |> Map.new()
    end
  end

  @spec stream(:gen_tcp.socket(), Http4e.Response.body_stream()) :: :ok
  defp stream(incoming_connection_request_socket, response_body_stream) when is_function(response_body_stream) do
    [yield: response_body_part, cont: cont] =
      response_body_stream.({})
    :gen_tcp.send(incoming_connection_request_socket, response_body_part)
    case cont do
      :nil ->
        :ok

      rest_response_body_stream when is_function(rest_response_body_stream) ->
        stream(incoming_connection_request_socket, rest_response_body_stream)
    end
  end
end
