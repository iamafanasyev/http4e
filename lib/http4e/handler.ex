defmodule Http4e.Handler do
  @type assignments() :: %{atom() => any()}

  @type t() :: ([assignments: assignments(), request: %Http4e.Request{}] -> %Http4e.Response{})
end
