defmodule Binary do

  def right_shift(binary, num_bytes, opts \\ []) do
    rotate = Keyword.get(opts, :rotate, false)

    size = byte_size(binary)
    left_size = size - num_bytes
    num_bits = num_bytes * 8
    <<left::bytes-size(left_size), right::bytes-size(num_bytes)>> = binary

    case rotate do
      true -> right <> left
      false -> <<0::size(num_bits)>> <> left
    end
  end

  def xor(first, second, opts \\ []) do
    align = Keyword.get(opts, :align, :left)
    trim = Keyword.get(opts, :trim, true)
    :crypto.exor(first, second)
  end

end
