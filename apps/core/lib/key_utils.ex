defmodule Volta.KeyUtils do
  require Integer
  use Bitwise

  def valid_public_key?(<<4, _x::unsigned-size(256), _y::unsigned-size(256)>>), do: true
  def valid_public_key?(<<2, _::bytes-size(32)>>), do: true
  def valid_public_key?(<<3, _::bytes-size(32)>>), do: true
  def valid_public_key?(_other), do: false
  
  def as_uint(<<i::unsigned-size(256)>>), do: i

  def xy_to_key({x, y}) do
    <<4, x::unsigned-size(256), y::unsigned-size(256)>>
  end

  def xy(<<4, x::unsigned-size(256), y::unsigned-size(256)>>), do: {x, y}
  def xy(<<2, _::bytes-size(32)>> = key), do: key |> actually_decompress() |> xy()
  def xy(<<3, _::bytes-size(32)>> = key), do: key |> actually_decompress() |> xy()

  def compress(<<4, x::bytes-size(32), y::unsigned-size(256)>>) do
    if Integer.is_odd(y) do
      <<3>>
    else
      <<2>>
    end <> x
  end

  def compress(<<2, _::bytes-size(32)>> = key), do: key
  def compress(<<3, _::bytes-size(32)>> = key), do: key

  def decompress(<<4, _::bytes-size(64)>> = key), do: key
  def decompress(<<2, _::bytes-size(32)>> = key), do: actually_decompress(key)
  def decompress(<<3, _::bytes-size(32)>> = key), do: actually_decompress(key)

  defp actually_decompress(<<sign_byte, x::unsigned-size(256)>>) do
    a = 0
    b = 7
    p = 115792089237316195423570985008687907853269984665640564039457584007908834671663
    beta = power(x * x * x + a * x + b, div(p + 1, 4), p)
    y = 
    if Integer.is_even(beta + sign_byte) do
      beta
    else
      p - beta
    end
    <<4, x::unsigned-size(256), y::unsigned-size(256)>>
  end

  defp power(n, p, modulo) when p >= 0 and n > 0 do
    _power(n, p, modulo, 1)
  end

  defp _power(_, 0, _, accum), do: accum

  defp _power(n, p, modulo, accum) do
    accum =
      case p &&& 1 do
        0 ->
          accum

        1 ->
          mod(accum * n, modulo)
      end

    _power(mod(n * n, modulo), p >>> 1, modulo, accum)
  end

  defp mod(0, _), do: 0
  defp mod(x, y) when x > 0, do: rem(x, y)
  defp mod(x, y) when x < 0 do
    cond do
      rem(x, y) == 0 ->
        0

      true ->
        y + rem(x, y)
    end
  end

end
