defmodule Volta.Core.OnionTest do
  use ExUnit.Case, async: true
  alias Volta.Core.Onion
  alias Volta.Core.Onion.OnionPacketV0
  alias Volta.Core.Onion.HopData
  alias Volta.Core.Onion.PerHop

  test "parse & encode realm 0 per_hop" do
    binary = <<
      0, 0, 0, 0, 0, 0, 0, 1, # short_channel_id = 1
      0, 0, 0, 0, 0, 0, 0, 2, # amt_to_forward = 2
      0, 0, 0, 3,             # outgoing_cltv_value = 3
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, # padding
    >>
    realm = 0
    msg = %PerHop{short_channel_id: 1, amt_to_forward: 2, outgoing_cltv_value: 3}
    assert PerHop.parse(realm, binary) == msg
    assert PerHop.encode(msg) == binary
  end

  test "bolt 4 (onion) test vector" do
    pubkey_0 = "02eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619" |> bin()
    pubkey_1 = "0324653eac434488002cc06bbfb7f10fe18991e35f9fe4302dbea6d2353dc0ab1c" |> bin()
    pubkey_2 = "027f31ebc5462c1fdce1b737ecff52d37d75dea43ce11c74d25aa297165faa2007" |> bin()
    pubkey_3 = "032c0b7cf95324a07d05398b240174dc0c2be444d96b159aa6c7f7b1e668680991" |> bin()
    pubkey_4 = "02edabbd16b41c8371b92ef2f04c1185b4f03b6dcd52ba9b78d9d7c89c8f221145" |> bin()

    nhops = 5
    session_key = "4141414141414141414141414141414141414141414141414141414141414141" |> bin()
    associated_data = "4242424242424242424242424242424242424242424242424242424242424242" |> bin()

    hop_payload_0 = "000000000000000000000000000000000000000000000000000000000000000000" |> parse_hop_payload_hex()
    hop_payload_1 = "000101010101010101000000000000000100000001000000000000000000000000" |> parse_hop_payload_hex()
    hop_payload_2 = "000202020202020202000000000000000200000002000000000000000000000000" |> parse_hop_payload_hex()
    hop_payload_3 = "000303030303030303000000000000000300000003000000000000000000000000" |> parse_hop_payload_hex()
    hop_payload_4 = "000404040404040404000000000000000400000004000000000000000000000000" |> parse_hop_payload_hex()

    hops = [
      {pubkey_0, hop_payload_0},
      {pubkey_1, hop_payload_1},
      {pubkey_2, hop_payload_2},
      {pubkey_3, hop_payload_3},
      {pubkey_4, hop_payload_4},
    ]

    packet = OnionPacketV0.create(hops, session_key, associated_data)

  end

  defp parse_hop_payload_hex(h) do
    <<realm, rest::binary>> = bin(h)
    PerHop.parse(realm, rest)
  end

  defp hex(b) do
    Base.encode16(b, case: :lower)
  end

  defp bin(h) do
    Base.decode16!(h, case: :lower)
  end
end
