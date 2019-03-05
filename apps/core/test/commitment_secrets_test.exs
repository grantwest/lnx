defmodule Volta.Core.CommitmentSecretsTest do
  use ExUnit.Case, async: true
  alias Volta.Core.CommitmentSecrets

  test "create commitment seed" do
    seed = CommitmentSecrets.new_seed()
    assert is_binary(seed) == true
    assert byte_size(seed) == 32
  end

  test "calculate commitment from seed and index, Bolt 03 Appendix D" do
    seed = "0000000000000000000000000000000000000000000000000000000000000000" |> bin()
    i = 281474976710655
    expected = "02a40c85b6f28da08dfdbe0926c53fab2de6d28c10301f8f7c4073d5e42e3148"
    assert CommitmentSecrets.commitment(seed, i) |> hex() == expected

    seed = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" |> bin()
    i = 281474976710655
    expected = "7cc854b54e3e0dcdb010d7a3fee464a9687be6e8db3be6854c475621e007a5dc"
    assert CommitmentSecrets.commitment(seed, i) |> hex() == expected

    seed = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" |> bin()
    i = 0xaaaaaaaaaaa
    expected = "56f4008fb007ca9acf0e15b054d5c9fd12ee06cea347914ddbaed70d1c13a528"
    assert CommitmentSecrets.commitment(seed, i) |> hex() == expected

    seed = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" |> bin()
    i = 0x555555555555
    expected = "9015daaeb06dba4ccc05b91b2f73bd54405f2be9f217fbacd3c5ac2e62327d31"
    assert CommitmentSecrets.commitment(seed, i) |> hex() == expected

    seed = "0101010101010101010101010101010101010101010101010101010101010101" |> bin()
    i = 1
    expected = "915c75942a26bb3a433a8ce2cb0427c29ec6c1775cfc78328b57f6ba7bfeaa9c"
    assert CommitmentSecrets.commitment(seed, i) |> hex() == expected
  end


  defp hex(nil), do: nil
  defp hex(b) do
    Base.encode16(b, case: :lower)
  end

  defp bin(h) do
    Base.decode16!(h, case: :mixed)
  end

end
