defmodule Http4e.Url do
  @spec parse_query_parameters(query_string :: String.t()) :: Http4e.Request.query_parameters()
  def parse_query_parameters(query_string) when is_binary(query_string) do
    query_string
    |> String.split("&")
    |> Stream.map(fn encoded_query_parameter ->
      encoded_query_parameter
      |> String.split("=")
      |> case do
        [query_parameter_name] ->
          {query_parameter_name, ""}

        [query_parameter_name, query_parameter_value] ->
          {query_parameter_name, query_parameter_value}
      end
    end)
    |> Enum.reduce(
      Map.new(),
      fn {query_parameter_name, query_parameter_value}, query_parameters ->
        Map.put(
          query_parameters,
          query_parameter_name,
          Map.get(query_parameters, query_parameter_name, []) ++ [query_parameter_value]
        )
      end
    )
  end
end
