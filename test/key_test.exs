defmodule Lnx.KeyTest do
  use ExUnit.Case, async: true
  alias Lnx.Key


  test "compress" do
    pubkey = bin("0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6")
    assert Key.compress(pubkey) |> hex() == "0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352"

    pubkey = bin("0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba7")
    assert Key.compress(pubkey) |> hex() == "0350863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352"
  end

  test "decompress" do
    pubkey = bin("0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352")
    assert Key.decompress(pubkey) |> hex() == "0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6"

    pubkey = bin("036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7")
    assert Key.decompress(pubkey) |> hex() == "046360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7eb1c2784a65901538479361e94c0a2597973adef0836a6a7eddf50b7997c88a3"
  end

  test "compress decompress loop even" do
    key = "0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352"
    assert key
    |> bin()
    |> Key.decompress()
    |> Key.compress()
    |> hex() == key
  end

  test "compress decompress loop odd" do
    key = "036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7"
    assert key
    |> bin()
    |> Key.decompress()
    |> Key.compress()
    |> hex() == key
  end

  test "xy point from compressed key" do
    pub = bin("02466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f27")
    assert Key.xy(pub) == {31855367722742370537280679280108010854876607759940877706949385967087672770343, 46659058944867745027460438812818578793297503278458148978085384795486842595210}
  end

  test "xy point from decompressed key" do
    
  end

  test "public key from private key" do
    priv = "1111111111111111111111111111111111111111111111111111111111111111" |> bin()
    expected_pub = "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa"
    assert Key.pub_from_priv(priv) |> Key.compress() |> hex() == expected_pub
  end

  defp hex(b) do
    Base.encode16(b, case: :lower)
  end

  defp bin(h) do
    Base.decode16!(h, case: :lower)
  end
end
