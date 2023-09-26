defimpl Http4e.Server, for: Http4e.Server.GenTcp do
  @spec start(%Http4e.Server.GenTcp{}, Http4e.Handler.t()) :: Http4e.Server.shutdown()
  def start(server, handler) when is_function(handler, 1) do
    {:ok, listen_socket} =
      :gen_tcp.listen(
        server.listen_port,
        # https://www.erlang.org/doc/man/inet.html#setopts-2
        active: false,
        mode: :binary,
        packet: :http_bin
      )

    Task.start_link(fn ->
      handle_incoming_connection_requests(
        listen_socket,
        server.response_body_stream_reader,
        handler
      )
    end)

    fn -> :gen_tcp.close(listen_socket) end
  end

  @http_1_1_line_ending "\r\n"
  @http_1_1_protocol "HTTP/1.1"
  @spec handle_incoming_connection_requests(
          :gen_tcp.socket(),
          Http4e.BodyStream.Reader.t(),
          Http4e.Handler.t()
        ) :: :ok
  defp handle_incoming_connection_requests(listen_socket, response_body_stream_reader, handler) do
    {:ok, incoming_connection_request_socket} = :gen_tcp.accept(listen_socket, :infinity)

    Task.start(fn ->
      try do
        %{
          body_stream: response_body_stream,
          headers: headers,
          status: %Http4e.Response.Status{code: code, reason: reason},
        } =
          handler.(assignments: %{}, request: receive_request(incoming_connection_request_socket))

        # https://www.w3.org/Protocols/rfc2616/rfc2616-sec6.html
        response_first_line = "#{@http_1_1_protocol} #{code} #{reason}"

        response_header_lines = Enum.map(headers, fn {key, value} -> "#{key}: #{value}" end)

        response_metadata =
          Enum.join([response_first_line | response_header_lines], @http_1_1_line_ending)

        :gen_tcp.send(
          incoming_connection_request_socket,
          "#{response_metadata}#{@http_1_1_line_ending}#{@http_1_1_line_ending}"
        )

        :inet.setopts(incoming_connection_request_socket, packet: :http_bin)

        response_body_stream_reader
        |> Http4e.BodyStream.Reader.from(response_body_stream)
        |> Stream.each(&:gen_tcp.send(incoming_connection_request_socket, &1))
        |> Stream.run()
      after
        :gen_tcp.close(incoming_connection_request_socket)
      end
    end)

    handle_incoming_connection_requests(listen_socket, response_body_stream_reader, handler)
  end

  @spec receive_request(
          :gen_tcp.socket(),
          already_revealed_request_metadata :: %{atom() => any()}
        ) :: %Http4e.Request{}
  defp receive_request(
         incoming_connection_request_socket,
         %{headers: %{} = headers} = request \\ %{headers: %{}}
       ) do
    case :gen_tcp.recv(incoming_connection_request_socket, 0) do
      {:ok, {:http_request, method, {:abs_path, abs_path}, _}}
      when method in [:DELETE, :GET, :HEAD, :OPTIONS, :PATCH, :POST, :PUT, :TRACE] ->
        [path, query_string] =
          case String.split(abs_path, "?", parts: 2) do
            [path_without_query_string] ->
              [path_without_query_string, ""]

            path_with_query_string ->
              path_with_query_string
          end

        receive_request(
          incoming_connection_request_socket,
          %{
            headers: %{},
            method: method,
            path: path,
            query_parameters: Http4e.Url.parse_query_parameters(query_string),
          }
        )

      {
        :ok,
        {
          :http_header,
          _header_value_length,
          _header_key_string_or_atom,
          header_key,
          header_value
        }
      }
      when is_binary(header_key) and is_binary(header_value) ->
        receive_request(
          incoming_connection_request_socket,
          Map.put(
            request,
            :headers,
            Map.put(headers, String.downcase(header_key), header_value)
          )
        )

      {:ok, :http_eoh} ->
        case request do
          %{method: method_without_body}
          when method_without_body in [:DELETE, :GET, :HEAD, :OPTIONS, :TRACE] ->
            struct!(
              Http4e.Request,
              Map.put(request, :body_stream, Http4e.BodyStream.empty())
            )

          %{
            headers: %{
              "content-length" => content_length,
            },
            method: method_with_body,
          }
          when method_with_body in [:PATCH, :POST, :PUT] ->
            struct!(
              Http4e.Request,
              Map.put(
                request,
                :body_stream,
                build_request_body_stream(
                  incoming_connection_request_socket,
                  String.to_integer(content_length)
                )
              )
            )
        end
    end
  end

  @spec build_request_body_stream(
          :gen_tcp.socket(),
          request_body_size_in_bytes :: non_neg_integer()
        ) :: Http4e.BodyStream.t()
  defp build_request_body_stream(incoming_connection_request_socket, request_body_size_in_bytes)
       when request_body_size_in_bytes >= 0 do
    fn [body_part_size_in_bytes: body_part_size_in_bytes] when body_part_size_in_bytes >= 0 ->
      :inet.setopts(incoming_connection_request_socket, packet: :raw)

      bytes_number = min(body_part_size_in_bytes, request_body_size_in_bytes)

      case :gen_tcp.recv(incoming_connection_request_socket, bytes_number) do
        {:ok, request_body_part} when is_binary(request_body_part) ->
          [
            yield: request_body_part,
            cont:
              if request_body_size_in_bytes - bytes_number > 0 do
                build_request_body_stream(
                  incoming_connection_request_socket,
                  request_body_size_in_bytes - bytes_number
                )
              else
                nil
              end,
          ]
      end
    end
  end
end
