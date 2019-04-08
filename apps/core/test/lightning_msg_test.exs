defmodule Volta.LightningMsgTest do
  use ExUnit.Case, async: true
  alias Volta.Core.TestUtils.Random
  alias Volta.LightningMsg
  alias Volta.LightningMsg.UnknownMsg
  alias Volta.LightningMsg.InitMsg
  alias Volta.LightningMsg.ErrorMsg
  alias Volta.LightningMsg.PingMsg
  alias Volta.LightningMsg.PongMsg
  alias Volta.LightningMsg.OpenChannelMsg
  alias Volta.LightningMsg.AcceptChannelMsg
  alias Volta.LightningMsg.FundingCreatedMsg
  alias Volta.LightningMsg.FundingSignedMsg
  alias Volta.LightningMsg.FundingLockedMsg
  alias Volta.LightningMsg.ShutdownMsg
  alias Volta.LightningMsg.ClosingSignedMsg
  alias Volta.LightningMsg.UpdateAddHtlcMsg
  alias Volta.LightningMsg.UpdateFulfillHtlcMsg
  alias Volta.LightningMsg.UpdateFailHtlcMsg
  alias Volta.LightningMsg.UpdateFailMalformedHtlcMsg

  test "parse unknown message" do
    msg_binary = <<
      3, 233, # type = 1001 
      1,2,3,4 # payload
    >>
    assert LightningMsg.parse(msg_binary) == 
      %UnknownMsg{type: 1001, payload: <<1,2,3,4>>}
  end

  test "parse & encode init message (1 byte)" do
    msg_binary = <<
      0, 16,      # type = 16
      0, 1,       # gflen = 1
      0b10101010, # global features
      0, 1,       # lflen = 1
      0b11111111  # local features
    >>
    msg = %InitMsg{global_features: <<0b10101010>>, local_features: <<0b11111111>>}
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode init message (2+ bytes)" do
    msg_binary = <<
      0, 16,      # type = 16
      0, 2,       # gflen = 1
      3, 1,       # global features
      0, 3,       # lflen = 1
      3, 2, 1     # local features
    >>
    msg = %InitMsg{global_features: <<3, 1>>, local_features: <<3, 2, 1>>}
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
      
  end

  test "parse & encode error message" do
    msg_binary = <<
      0, 17,      # type = 17
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4, # channel id = 16909060
      0, 3,       # len = 3
      0, 1, 0     # data
    >>
    msg = %ErrorMsg{channel_id: 16909060, data: <<0, 1, 0>>}
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode ping msg" do
    msg_binary = <<
      0, 18,      # type = 18
      0, 4,       # num_pong_bytes = 4
      0, 3,       # ignored_len = 3
      0, 0, 0     # ignored
    >>
    msg = %PingMsg{ping_bytes: 3, pong_bytes: 4}
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode pong msg" do
    msg_binary = <<
      0, 19,      # type = 19
      0, 3,       # ignored_len = 3
      0, 0, 0     # ignored
    >>
    msg = %PongMsg{pong_bytes: 3}
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode open_channel msg" do
    funding_pubkey =             Random.bytes(33)
    revocation_basepoint =       Random.bytes(33)
    payment_basepoint =          Random.bytes(33)
    delayed_payment_basepoint =  Random.bytes(33)
    htlc_basepoint =             Random.bytes(33)
    first_per_commitment_point = Random.bytes(33)

    msg_binary = <<
      0, 32,                   # type = 32
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, # chain_hash = 1
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # temporary_channel_id = 2
      0, 0, 0, 0, 0, 0, 0, 3,  # funding_satoshis = 3
      0, 0, 0, 0, 0, 0, 0, 4,  # push_msat = 4
      0, 0, 0, 0, 0, 0, 0, 5,  # dust_limit_satoshis = 5
      0, 0, 0, 0, 0, 0, 0, 6,  # max_htlc_value_in_flight_msat = 6
      0, 0, 0, 0, 0, 0, 0, 7,  # channel_reserve_satoshis = 7
      0, 0, 0, 0, 0, 0, 0, 8,  # htlc_minimum_msat = 8
      0, 0, 0, 9,              # feerate_per_kw = 9
      0, 10,                   # to_self_delay = 10
      0, 11,                   # max_accepted_htlcs = 11
    >> 
    <> funding_pubkey
    <> revocation_basepoint
    <> payment_basepoint
    <> delayed_payment_basepoint
    <> htlc_basepoint
    <> first_per_commitment_point
    <> <<
      18,                      # channel_flags = 00010010
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
    funding_pubkey =             Random.bytes(33)
    revocation_basepoint =       Random.bytes(33)
    payment_basepoint =          Random.bytes(33)
    delayed_payment_basepoint =  Random.bytes(33)
    htlc_basepoint =             Random.bytes(33)
    first_per_commitment_point = Random.bytes(33)

    msg_binary = <<
      0, 33,                   # type = 33
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # temporary_channel_id = 2
      0, 0, 0, 0, 0, 0, 0, 5,  # dust_limit_satoshis = 5
      0, 0, 0, 0, 0, 0, 0, 6,  # max_htlc_value_in_flight_msat = 6
      0, 0, 0, 0, 0, 0, 0, 7,  # channel_reserve_satoshis = 7
      0, 0, 0, 0, 0, 0, 0, 8,  # htlc_minimum_msat = 8
      0, 0, 0, 9,              # minimum_depth = 9
      0, 10,                   # to_self_delay = 10
      0, 11,                   # max_accepted_htlcs = 11
    >> 
    <> funding_pubkey
    <> revocation_basepoint
    <> payment_basepoint
    <> delayed_payment_basepoint
    <> htlc_basepoint
    <> first_per_commitment_point
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

    msg_binary = <<
      0, 34,  # type = 34
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # temporary_channel_id = 2
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, # funding_txid = 3
      0, 4,   # funding_output_index = 4
    >> 
    <> signature

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

    msg_binary = <<
      0, 35,  # type = 35
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # channel_id = 2
    >> 
    <> signature

    msg = %FundingSignedMsg{
      channel_id: 2,
      signature: signature
    }
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode funding_locked msg" do
    next_per_commitment_point = Random.bytes(33)

    msg_binary = <<
      0, 36,  # type = 36
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # channel_id = 2
    >> 
    <> next_per_commitment_point

    msg = %FundingLockedMsg{
      channel_id: 2,
      next_per_commitment_point: next_per_commitment_point
    }
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode shutdown msg" do
    msg_binary = <<
      0, 38,      # type = 36
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # channel_id = 2
      0, 4,       # len = 4
      1, 2, 3, 4, # scriptpubkey = 2
    >> 

    msg = %ShutdownMsg{
      channel_id: 2,
      scriptpubkey: <<1, 2, 3, 4>>,
    }
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode closing_signed msg" do
    signature = Random.bytes(64)
    msg_binary = <<
      0, 39,      # type = 36
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # channel_id = 2
      0, 0, 0, 0, 0, 0, 0, 4, # fee_satoshi = 4
    >> <> signature

    msg = %ClosingSignedMsg{
      channel_id: 2,
      fee_satoshi: 4,
      signature: signature,
    }
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode update_add_htlc msg" do
    onion_packet = Random.bytes(1366)

    msg_binary = <<
      0, 128,  # type = 128
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # channel_id = 2
      0, 0, 0, 0, 0, 0, 0, 8, # id = 8
      0, 0, 0, 0, 0, 0, 0, 5, # amount_msat = 5
      1, 2, 3, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 7, 8, 9, # payment_hash
      0, 0, 0, 3, # cltv_expiry
    >> <> onion_packet

    msg = %UpdateAddHtlcMsg{
      channel_id: 2,
      id: 8,
      amount_msat: 5,
      payment_hash: <<1, 2, 3, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 7, 8, 9>>,
      cltv_expiry: 3,
      onion_routing_packet: onion_packet,
    }
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode update_fulfill_htlc msg" do
    preimage = Random.bytes(32)

    msg_binary = <<
      0, 130,  # type = 130
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # channel_id = 2
      0, 0, 0, 0, 0, 0, 0, 8, # id = 8
    >> <> preimage

    msg = %UpdateFulfillHtlcMsg{
      channel_id: 2,
      id: 8,
      payment_preimage: preimage,
    }
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode update_fail_htlc msg" do
    reason = "this is the reason"

    msg_binary = <<
      0, 131,  # type = 131
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # channel_id = 2
      0, 0, 0, 0, 0, 0, 0, 8, # id = 8
      0, 18, # len = 18
    >> <> reason

    msg = %UpdateFailHtlcMsg{
      channel_id: 2,
      id: 8,
      reason: "this is the reason",
    }
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

  test "parse & encode update_fail_malformed_htlc msg" do
    sha256 = Random.bytes(32)
    msg_binary = <<
      0, 135,  # type = 135
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, # channel_id = 2
      0, 0, 0, 0, 0, 0, 0, 8, # id = 8
      sha256::bytes(),
      0, 19, # failure_code = 19
    >>

    msg = %UpdateFailMalformedHtlcMsg{
      channel_id: 2,
      id: 8,
      sha256_of_onion: sha256,
      failure_code: 19,
    }
    assert LightningMsg.parse(msg_binary) == msg
    assert LightningMsg.encode(msg) == msg_binary
  end

end
