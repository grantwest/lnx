defmodule Lnx.LightningMsgTest do
  use ExUnit.Case, async: true
  alias Lnx.TestUtils.Random
  alias Lnx.LightningMsg
  alias Lnx.LightningMsg.UnknownMsg
  alias Lnx.LightningMsg.InitMsg
  alias Lnx.LightningMsg.ErrorMsg
  alias Lnx.LightningMsg.PingMsg
  alias Lnx.LightningMsg.PongMsg
  alias Lnx.LightningMsg.OpenChannelMsg
  alias Lnx.LightningMsg.AcceptChannelMsg
  alias Lnx.LightningMsg.FundingCreatedMsg
  alias Lnx.LightningMsg.FundingSignedMsg
  alias Lnx.LightningMsg.FundingLockedMsg
  alias Lnx.LightningMsg.ShutdownMsg
  alias Lnx.LightningMsg.ClosingSignedMsg
  alias Lnx.LightningMsg.UpdateAddHtlcMsg
  alias Lnx.LightningMsg.UpdateFulfillHtlcMsg
  alias Lnx.LightningMsg.UpdateFailHtlcMsg
  alias Lnx.LightningMsg.UpdateFailMalformedHtlcMsg

  test "parse unknown message" do
    msg_binary = <<
      # type = 1001
      3,
      233,
      # payload
      1,
      2,
      3,
      4
    >>

    assert LightningMsg.parse(msg_binary) ==
             %UnknownMsg{type: 1001, payload: <<1, 2, 3, 4>>}
  end

  test "parse & encode init message (1 byte)" do
    msg_binary = <<
      # type = 16
      0,
      16,
      # gflen = 1
      0,
      1,
      # global features
      0b10101010,
      # lflen = 1
      0,
      1,
      # local features
      0b11111111
    >>

    msg = %InitMsg{global_features: <<0b10101010>>, local_features: <<0b11111111>>}
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode init message (2+ bytes)" do
    msg_binary = <<
      # type = 16
      0,
      16,
      # gflen = 1
      0,
      2,
      # global features
      3,
      1,
      # lflen = 1
      0,
      3,
      # local features
      3,
      2,
      1
    >>

    msg = %InitMsg{global_features: <<3, 1>>, local_features: <<3, 2, 1>>}
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode error message" do
    msg_binary = <<
      # type = 17
      0,
      17,
      # channel id = 16909060
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      2,
      3,
      4,
      # len = 3
      0,
      3,
      # data
      0,
      1,
      0
    >>

    msg = %ErrorMsg{channel_id: 16_909_060, data: <<0, 1, 0>>}
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode ping msg" do
    msg_binary = <<
      # type = 18
      0,
      18,
      # num_pong_bytes = 4
      0,
      4,
      # ignored_len = 3
      0,
      3,
      # ignored
      0,
      0,
      0
    >>

    msg = %PingMsg{ping_bytes: 3, pong_bytes: 4}
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode pong msg" do
    msg_binary = <<
      # type = 19
      0,
      19,
      # ignored_len = 3
      0,
      3,
      # ignored
      0,
      0,
      0
    >>

    msg = %PongMsg{pong_bytes: 3}
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode open_channel msg" do
    funding_pubkey = Random.bytes(33)
    revocation_basepoint = Random.bytes(33)
    payment_basepoint = Random.bytes(33)
    delayed_payment_basepoint = Random.bytes(33)
    htlc_basepoint = Random.bytes(33)
    first_per_commitment_point = Random.bytes(33)

    msg_binary =
      <<
        # type = 32
        0,
        32,
        # chain_hash = 1
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1,
        # temporary_channel_id = 2
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2,
        # funding_satoshis = 3
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        3,
        # push_msat = 4
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        4,
        # dust_limit_satoshis = 5
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        5,
        # max_htlc_value_in_flight_msat = 6
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        6,
        # channel_reserve_satoshis = 7
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        7,
        # htlc_minimum_msat = 8
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        8,
        # feerate_per_kw = 9
        0,
        0,
        0,
        9,
        # to_self_delay = 10
        0,
        10,
        # max_accepted_htlcs = 11
        0,
        11
      >> <>
        funding_pubkey <>
        revocation_basepoint <>
        payment_basepoint <>
        delayed_payment_basepoint <>
        htlc_basepoint <>
        first_per_commitment_point <>
        <<
          # channel_flags = 00010010
          18
        >>

    # 0, 4,                    # shudown_len = 19
    # 1, 2, 3, 4               # shutdown_scriptpubkey
    msg = %OpenChannelMsg{
      chain_hash: 1,
      temporary_channel_id: 2,
      funding_satoshis: 3,
      push_msat: 4,
      dust_limit_satoshis: 5,
      max_htlc_value_in_flight_msat: 6,
      channel_reserve_satoshis: 7,
      htlc_minimum_msat: 8,
      feerate_per_kw: 9,
      to_self_delay: 10,
      max_accepted_htlcs: 11,
      funding_pubkey: funding_pubkey,
      revocation_basepoint: revocation_basepoint,
      payment_basepoint: payment_basepoint,
      delayed_payment_basepoint: delayed_payment_basepoint,
      htlc_basepoint: htlc_basepoint,
      first_per_commitment_point: first_per_commitment_point,
      channel_flags: 18,
      shutdown_scriptpubkey: :none
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode accept_channel msg" do
    funding_pubkey = Random.bytes(33)
    revocation_basepoint = Random.bytes(33)
    payment_basepoint = Random.bytes(33)
    delayed_payment_basepoint = Random.bytes(33)
    htlc_basepoint = Random.bytes(33)
    first_per_commitment_point = Random.bytes(33)

    msg_binary =
      <<
        # type = 33
        0,
        33,
        # temporary_channel_id = 2
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2,
        # dust_limit_satoshis = 5
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        5,
        # max_htlc_value_in_flight_msat = 6
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        6,
        # channel_reserve_satoshis = 7
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        7,
        # htlc_minimum_msat = 8
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        8,
        # minimum_depth = 9
        0,
        0,
        0,
        9,
        # to_self_delay = 10
        0,
        10,
        # max_accepted_htlcs = 11
        0,
        11
      >> <>
        funding_pubkey <>
        revocation_basepoint <>
        payment_basepoint <>
        delayed_payment_basepoint <>
        htlc_basepoint <>
        first_per_commitment_point

    # 0, 4,                    # shudown_len = 19
    # 1, 2, 3, 4               # shutdown_scriptpubkey
    msg = %AcceptChannelMsg{
      temporary_channel_id: 2,
      dust_limit_satoshis: 5,
      max_htlc_value_in_flight_msat: 6,
      channel_reserve_satoshis: 7,
      htlc_minimum_msat: 8,
      minimum_depth: 9,
      to_self_delay: 10,
      max_accepted_htlcs: 11,
      funding_pubkey: funding_pubkey,
      revocation_basepoint: revocation_basepoint,
      payment_basepoint: payment_basepoint,
      delayed_payment_basepoint: delayed_payment_basepoint,
      htlc_basepoint: htlc_basepoint,
      first_per_commitment_point: first_per_commitment_point,
      shutdown_scriptpubkey: :none
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode funding_created msg" do
    signature = Random.bytes(64)

    msg_binary =
      <<
        # type = 34
        0,
        34,
        # temporary_channel_id = 2
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2,
        # funding_txid = 3
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        3,
        # funding_output_index = 4
        0,
        4
      >> <>
        signature

    msg = %FundingCreatedMsg{
      temporary_channel_id: 2,
      funding_txid: 3,
      funding_output_index: 4,
      signature: signature
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode funding_signed msg" do
    signature = Random.bytes(64)

    msg_binary =
      <<
        # type = 35
        0,
        35,
        # channel_id = 2
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2
      >> <>
        signature

    msg = %FundingSignedMsg{
      channel_id: 2,
      signature: signature
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode funding_locked msg" do
    next_per_commitment_point = Random.bytes(33)

    msg_binary =
      <<
        # type = 36
        0,
        36,
        # channel_id = 2
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2
      >> <>
        next_per_commitment_point

    msg = %FundingLockedMsg{
      channel_id: 2,
      next_per_commitment_point: next_per_commitment_point
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode shutdown msg" do
    msg_binary = <<
      # type = 36
      0,
      38,
      # channel_id = 2
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      # len = 4
      0,
      4,
      # scriptpubkey = 2
      1,
      2,
      3,
      4
    >>

    msg = %ShutdownMsg{
      channel_id: 2,
      scriptpubkey: <<1, 2, 3, 4>>
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode closing_signed msg" do
    signature = Random.bytes(64)

    msg_binary =
      <<
        # type = 36
        0,
        39,
        # channel_id = 2
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2,
        # fee_satoshi = 4
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        4
      >> <> signature

    msg = %ClosingSignedMsg{
      channel_id: 2,
      fee_satoshi: 4,
      signature: signature
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode update_add_htlc msg" do
    onion_packet = Random.bytes(1366)

    msg_binary =
      <<
        # type = 128
        0,
        128,
        # channel_id = 2
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2,
        # id = 8
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        8,
        # amount_msat = 5
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        5,
        # payment_hash
        1,
        2,
        3,
        4,
        5,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        6,
        7,
        8,
        9,
        # cltv_expiry
        0,
        0,
        0,
        3
      >> <> onion_packet

    msg = %UpdateAddHtlcMsg{
      channel_id: 2,
      id: 8,
      amount_msat: 5,
      payment_hash:
        <<1, 2, 3, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6,
          7, 8, 9>>,
      cltv_expiry: 3,
      onion_routing_packet: onion_packet
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode update_fulfill_htlc msg" do
    preimage = Random.bytes(32)

    msg_binary =
      <<
        # type = 130
        0,
        130,
        # channel_id = 2
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2,
        # id = 8
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        8
      >> <> preimage

    msg = %UpdateFulfillHtlcMsg{
      channel_id: 2,
      id: 8,
      payment_preimage: preimage
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode update_fail_htlc msg" do
    reason = "this is the reason"

    msg_binary =
      <<
        # type = 131
        0,
        131,
        # channel_id = 2
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2,
        # id = 8
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        8,
        # len = 18
        0,
        18
      >> <> reason

    msg = %UpdateFailHtlcMsg{
      channel_id: 2,
      id: 8,
      reason: "this is the reason"
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode update_fail_malformed_htlc msg" do
    sha256 = Random.bytes(32)

    msg_binary = <<
      # type = 135
      0,
      135,
      # channel_id = 2
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      # id = 8
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      8,
      sha256::bytes,
      # failure_code = 19
      0,
      19
    >>

    msg = %UpdateFailMalformedHtlcMsg{
      channel_id: 2,
      id: 8,
      sha256_of_onion: sha256,
      failure_code: 19
    }

    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end
end
