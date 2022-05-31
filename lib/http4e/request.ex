defmodule Http4e.Request do
  @type body_stream :: Coroutine.t([body_part_size_in_bytes: non_neg_integer()], body_part :: String.t())
  @type headers :: %{downcased_key :: String.t() => original_value :: String.t()}

  @type t :: %{
               headers: headers(),
               method: :DELETE | :GET | :HEAD | :OPTIONS | :TRACE,
               path: String.t(),
               query_parameters: %{String.t() => String.t()},
             }
             | %{
               await_body: (-> body :: String.t()),
               body_stream: body_stream(),
               headers: headers(),
               method: :PATCH | :POST | :PUT,
               path: String.t(),
               query_parameters: %{String.t() => String.t()},
             }
end
