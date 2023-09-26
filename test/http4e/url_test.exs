defmodule Http4e.UrlTest do
  use ExUnit.Case

  describe "&Url.parse_query_parameters/1" do
    test "should interpret query parameter without value as an empty string" do
      assert %{"bar" => [""], "foo" => [""]} = Http4e.Url.parse_query_parameters("foo&bar")
    end

    test "should preserve query parameter value occurrence order" do
      assert %{"bar" => ["1", "2", ""], "baz" => ["a", "b"], "foo" => ["", "foo"]} =
               Http4e.Url.parse_query_parameters("foo&bar=1&baz=a&bar=2&foo=foo&baz=b&bar=")
    end
  end
end
