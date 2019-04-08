defmodule Volta.Core.TestUtils.RandomTest do
  use ExUnit.Case, async: true
  alias Volta.Core.TestUtils.Random

  test "bytes produces correct length binary" do
    assert is_binary(Random.bytes(0))
    assert is_binary(Random.bytes(1))
    assert byte_size(Random.bytes(0)) == 0
    assert byte_size(Random.bytes(1)) == 1
    assert byte_size(Random.bytes(2)) == 2
    assert byte_size(Random.bytes(256)) == 256
    assert byte_size(Random.bytes(1024)) == 1024
  end

  test "bytes raises exception on negative num_bytes" do
    assert_raise RuntimeError, fn -> Random.bytes(-1) end
  end

end
