defmodule Http4e.Response do
  @type body_stream :: Coroutine.t({}, body_part :: String.t())

  @type t :: %{
               body_stream: body_stream(),
               headers: %{String.t() => String.t()},
               status: [code: non_neg_integer(), reason: String.t()],
             }

  defmodule Status do
    @type t :: [code: non_neg_integer(), reason: String.t()]

    @spec ok() :: Status.t()
    def ok() do
      [code: 200, reason: "OK"]
    end

    @spec not_found() :: Status.t()
    def not_found() do
      [code: 404, reason: "Not Found"]
    end
  end
end
