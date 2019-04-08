defmodule Lnx.TestUtils.Random do
  def bytes(0), do: <<>>

  def bytes(num_bytes) when num_bytes < 0 do
    raise "can't generate random bytes of negative size"
  end

  def bytes(num_bytes) do
    Enum.reduce(1..num_bytes, <<>>, fn _, acc ->
      acc <> <<:rand.uniform(256) - 1>>
    end)
  end
end
