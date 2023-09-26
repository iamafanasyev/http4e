defmodule Http4e.Filter do
  @type t() :: (Http4e.Handler.t() -> Http4e.Handler.t())
end
