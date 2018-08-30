defmodule CqpdemoTest do
  use ExUnit.Case
  doctest Cqpdemo

  test "greets the world" do
    assert Cqpdemo.hello() == :world
  end
end
