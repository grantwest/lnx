defmodule VoltaTest do
  use ExUnit.Case
  doctest Volta

  test "greets the world" do
    assert Volta.hello() == :world
  end
end
