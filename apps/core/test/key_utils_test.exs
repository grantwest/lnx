defmodule Volta.KeyUtilsTest do
  use ExUnit.Case, async: true
  alias Volta.KeyUtils


  test "compress" do
    pubkey = bin("0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6")
    assert KeyUtils.compress(pubkey) |> hex() == "0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352"

    pubkey = bin("0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba7")
    assert KeyUtils.compress(pubkey) |> hex() == "0350863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352"
  end

  test "decompress" do
    pubkey = bin("0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352")
    assert KeyUtils.decompress(pubkey) |> hex() == "0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6"

    pubkey = bin("036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7")
    assert KeyUtils.decompress(pubkey) |> hex() == "046360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7eb1c2784a65901538479361e94c0a2597973adef0836a6a7eddf50b7997c88a3"
  end

  test "compress decompress loop even" do
    key = "0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352"
    assert key
    |> bin()
    |> KeyUtils.decompress()
    |> KeyUtils.compress()
    |> hex() == key
  end

  test "compress decompress loop odd" do
    key = "036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7"
    assert key
    |> bin()
    |> KeyUtils.decompress()
    |> KeyUtils.compress()
    |> hex() == key
  end

  test "xy point from compressed key" do
    pub = bin("02466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f27")
    assert KeyUtils.xy(pub) == {31855367722742370537280679280108010854876607759940877706949385967087672770343, 46659058944867745027460438812818578793297503278458148978085384795486842595210}
  end

  test "xy point from decompressed key" do
    
  end

  defp hex(b) do
    Base.encode16(b, case: :lower)
  end

  defp bin(h) do
    Base.decode16!(h, case: :lower)
  end
end
