defmodule Lnx.BinaryTest do
  use ExUnit.Case, async: true

  test "right shift" do
    assert Binary.right_shift(<<1, 2, 3, 4>>, 2) == <<0, 0, 1, 2>>
  end

  test "right shift, no rotation" do
    assert Binary.right_shift(<<1, 2, 3, 4>>, 2, rotate: false) == <<0, 0, 1, 2>>
  end

  test "right shift with rotation" do
    assert Binary.right_shift(<<1, 2, 3, 4>>, 2, rotate: true) == <<3, 4, 1, 2>>
  end

  # test "xor" do
  #   assert Binary.xor(<<1>>, <<2>>) == <<3>>
  #   assert Binary.xor(<<1, 5>>, <<2, 5>>) == <<3, 0>>
  #   assert Binary.xor(<<1>>, <<2, 0>>, [align: :left, trim: true]) == <<3>>
  # end

  # test "xor left align & trim" do
  #   assert Binary.xor(<<1>>, <<2, 0>>, [align: :left, trim: true]) == <<3>>
  # end
end
