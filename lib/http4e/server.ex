defprotocol Http4e.Server do
  @type t() :: any()

  @type shutdown() :: (() -> :ok)

  @spec start(t(), Http4e.Handler.t()) :: shutdown()
  def start(server, handler)
end
