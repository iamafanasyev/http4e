defmodule Http4e.Server.Behaviour do
  @callback start(
              handler: Http4e.Handler.Behaviour.t(),
              listen_port: non_neg_integer()
            ) :: {:ok, shutdown_server :: (() -> :ok)}
end
