defmodule Volta.LightningMsg do
  @init 16
  @error 17
  @ping 18
  @pong 19
  @open_channel 32
  @accept_channel 33
  @funding_created 34
  @funding_signed 35
  @funding_locked 36
  @shutdown 38
  @closing_signed 39
  @update_add_htlc 128
  @update_fulfill_htlc 130
  @update_fail_htlc 131
  @update_fail_malformed_htlc 135


  defmodule UnknownMsg do
    defstruct [:type, :payload]
  end

  defmodule InitMsg do
    defstruct [global_features: <<>>, local_features: <<0>>]
  end

  defmodule ErrorMsg do
    defstruct [:channel_id, :data]
  end

  defmodule PingMsg do
    defstruct [:ping_bytes, :pong_bytes]
  end

  defmodule PongMsg do
    defstruct [:pong_bytes]
  end

  defmodule OpenChannelMsg do
    defstruct [
      :chain_hash,
      :temporary_channel_id,
      :funding_satoshis,
      :push_msat,
      :dust_limit_satoshis,
      :max_htlc_value_in_flight_msat,
      :channel_reserve_satoshis,
      :htlc_minimum_msat,
      :feerate_per_kw,
      :to_self_delay,
      :max_accepted_htlcs,
      :funding_pubkey,
      :revocation_basepoint,
      :payment_basepoint,
      :delayed_payment_basepoint,
      :htlc_basepoint,
      :first_per_commitment_point,
      :channel_flags,
      :shutdown_scriptpubkey,
    ]
  end

  defmodule AcceptChannelMsg do
    defstruct [
      :temporary_channel_id,
      :dust_limit_satoshis,
      :max_htlc_value_in_flight_msat,
      :channel_reserve_satoshis,
      :htlc_minimum_msat,
      :minimum_depth,
      :to_self_delay,
      :max_accepted_htlcs,
      :funding_pubkey,
      :revocation_basepoint,
      :payment_basepoint,
      :delayed_payment_basepoint,
      :htlc_basepoint,
      :first_per_commitment_point,
      :shutdown_scriptpubkey,
    ]
  end

  defmodule FundingCreatedMsg do
    defstruct [
      :temporary_channel_id,
      :funding_txid,
      :funding_output_index,
      :signature,
    ]
  end

  defmodule FundingSignedMsg do
    defstruct [
      :channel_id,
      :signature,
    ]
  end

  defmodule FundingLockedMsg do
    defstruct [
      :channel_id,
      :next_per_commitment_point,
    ]
  end

  defmodule ShutdownMsg do
    defstruct [
      :channel_id,
      :scriptpubkey,
    ]
  end

  defmodule ClosingSignedMsg do
    defstruct [
      :channel_id,
      :fee_satoshi,
      :signature,
    ]
  end

  defmodule UpdateAddHtlcMsg do
    defstruct [
      :channel_id,
      :id,
      :amount_msat,
      :payment_hash,
      :cltv_expiry,
      :onion_routing_packet,
    ] 
  end

  defmodule UpdateFulfillHtlcMsg do
    defstruct [
      :channel_id,
      :id,
      :payment_preimage,
    ] 
  end

  defmodule UpdateFailHtlcMsg do
    defstruct [
      :channel_id,
      :id,
      :reason,
    ] 
  end

  defmodule UpdateFailMalformedHtlcMsg do
    defstruct [
      :channel_id,
      :id,
      :sha256_of_onion,
      :failure_code,
    ] 
  end

  def parse(<<type::unsigned-big-size(16), payload::binary>>) do
    parse_type(type, payload)
  end

  def parse_type(
        @init,
        <<gflen::unsigned-big-size(16), gf::bytes-size(gflen), 
          lflen::unsigned-big-size(16), lf::bytes-size(lflen)>>) do
    %InitMsg{global_features: gf, local_features: lf}
  end

  def parse_type(
        @error,
        <<ch::unsigned-big-size(256), 
          data_len::unsigned-big-size(16), data::bytes-size(data_len)>>) do
    %ErrorMsg{channel_id: ch, data: data}
  end

  def parse_type(
        @ping,
        <<pong_bytes::unsigned-big-size(16),
          ignore_len::unsigned-big-size(16), _::bytes-size(ignore_len)>>) do
    %PingMsg{ping_bytes: ignore_len, pong_bytes: pong_bytes}        
  end

  def parse_type(
        @pong,
        <<ignore_len::unsigned-big-size(16), _::bytes-size(ignore_len)>>) do
    %PongMsg{pong_bytes: ignore_len}        
  end

  def parse_type(
        @open_channel,
        <<chain_hash::unsigned-big-size(256),
          temporary_channel_id::unsigned-big-size(256),
          funding_satoshis::unsigned-big-size(64),
          push_msat::unsigned-big-size(64),
          dust_limit_satoshis::unsigned-big-size(64),
          max_htlc_value_in_flight_msat::unsigned-big-size(64),
          channel_reserve_satoshis::unsigned-big-size(64),
          htlc_minimum_msat::unsigned-big-size(64),
          feerate_per_kw::unsigned-big-size(32),
          to_self_delay::unsigned-big-size(16),
          max_accepted_htlcs::unsigned-big-size(16),
          funding_pubkey::bytes-size(33),
          revocation_basepoint::bytes-size(33),
          payment_basepoint::bytes-size(33),
          delayed_payment_basepoint::bytes-size(33),
          htlc_basepoint::bytes-size(33),
          first_per_commitment_point::bytes-size(33),
          channel_flags,
          >>) do
    %OpenChannelMsg{
      chain_hash: chain_hash,
      temporary_channel_id: temporary_channel_id,
      funding_satoshis: funding_satoshis,
      push_msat: push_msat,
      dust_limit_satoshis: dust_limit_satoshis,
      max_htlc_value_in_flight_msat: max_htlc_value_in_flight_msat,
      channel_reserve_satoshis: channel_reserve_satoshis,
      htlc_minimum_msat: htlc_minimum_msat,
      feerate_per_kw: feerate_per_kw,
      to_self_delay: to_self_delay,
      max_accepted_htlcs: max_accepted_htlcs,
      funding_pubkey: funding_pubkey,
      revocation_basepoint: revocation_basepoint,
      payment_basepoint: payment_basepoint,
      delayed_payment_basepoint: delayed_payment_basepoint,
      htlc_basepoint: htlc_basepoint,
      first_per_commitment_point: first_per_commitment_point,
      channel_flags: channel_flags,
      shutdown_scriptpubkey: :none,
    }
  end

  def parse_type(
        @accept_channel,
        <<temporary_channel_id::unsigned-big-size(256),
          dust_limit_satoshis::unsigned-big-size(64),
          max_htlc_value_in_flight_msat::unsigned-big-size(64),
          channel_reserve_satoshis::unsigned-big-size(64),
          htlc_minimum_msat::unsigned-big-size(64),
          minimum_depth::unsigned-big-size(32),
          to_self_delay::unsigned-big-size(16),
          max_accepted_htlcs::unsigned-big-size(16),
          funding_pubkey::bytes-size(33),
          revocation_basepoint::bytes-size(33),
          payment_basepoint::bytes-size(33),
          delayed_payment_basepoint::bytes-size(33),
          htlc_basepoint::bytes-size(33),
          first_per_commitment_point::bytes-size(33),
          >>) do
    %AcceptChannelMsg{
      temporary_channel_id: temporary_channel_id,
      dust_limit_satoshis: dust_limit_satoshis,
      max_htlc_value_in_flight_msat: max_htlc_value_in_flight_msat,
      channel_reserve_satoshis: channel_reserve_satoshis,
      htlc_minimum_msat: htlc_minimum_msat,
      minimum_depth: minimum_depth,
      to_self_delay: to_self_delay,
      max_accepted_htlcs: max_accepted_htlcs,
      funding_pubkey: funding_pubkey,
      revocation_basepoint: revocation_basepoint,
      payment_basepoint: payment_basepoint,
      delayed_payment_basepoint: delayed_payment_basepoint,
      htlc_basepoint: htlc_basepoint,
      first_per_commitment_point: first_per_commitment_point,
      shutdown_scriptpubkey: :none,
    }
  end

  def parse_type(
        @funding_created,
        <<temporary_channel_id::unsigned-big-size(256),
          funding_txid::unsigned-big-size(256),
          funding_output_index::unsigned-big-size(16),
          signature::bytes-size(64),
          >>) do
    %FundingCreatedMsg{
      temporary_channel_id: temporary_channel_id,
      funding_txid: funding_txid,
      funding_output_index: funding_output_index,
      signature: signature,
    }
  end

  def parse_type(
        @funding_signed,
        <<channel_id::unsigned-big-size(256),
          signature::bytes-size(64),
          >>) do
    %FundingSignedMsg{
      channel_id: channel_id,
      signature: signature,
    }
  end

  def parse_type(
        @funding_locked,
        <<channel_id::unsigned-big-size(256),
          next_per_commitment_point::bytes-size(33),
          >>) do
    %FundingLockedMsg{
      channel_id: channel_id,
      next_per_commitment_point: next_per_commitment_point,
    }
  end

  def parse_type(
        @shutdown,
        <<channel_id::unsigned-big-size(256),
          len::unsigned-big-size(16),
          scriptpubkey::bytes-size(len),
          >>) do
    %ShutdownMsg{
      channel_id: channel_id,
      scriptpubkey: scriptpubkey,
    }
  end

  def parse_type(
        @closing_signed,
        <<channel_id::unsigned-big-size(256),
          fee_satoshi::unsigned-big-size(64),
          signature::bytes-size(64),
          >>) do
    %ClosingSignedMsg{
      channel_id: channel_id,
      fee_satoshi: fee_satoshi,
      signature: signature,
    }
  end

  def parse_type(
        @update_add_htlc,
        <<channel_id::unsigned-big-size(256),
          id::unsigned-big-size(64),
          amount_msat::unsigned-big-size(64),
          payment_hash::bytes-size(32),
          cltv_expiry::unsigned-big-size(32),
          onion_routing_packet::bytes-size(1366),
          >>) do
    %UpdateAddHtlcMsg{
      channel_id: channel_id,
      id: id,
      amount_msat: amount_msat,
      payment_hash: payment_hash,
      cltv_expiry: cltv_expiry,
      onion_routing_packet: onion_routing_packet,
    }
  end

  def parse_type(
        @update_fulfill_htlc,
        <<channel_id::unsigned-big-size(256),
          id::unsigned-big-size(64),
          payment_preimage::bytes-size(32),
          >>) do
    %UpdateFulfillHtlcMsg{
      channel_id: channel_id,
      id: id,
      payment_preimage: payment_preimage,
    }
  end

  def parse_type(
        @update_fail_htlc,
        <<channel_id::unsigned-big-size(256),
          id::unsigned-big-size(64),
          len::unsigned-big-size(16),
          reason::bytes-size(len),
          >>) do
    %UpdateFailHtlcMsg{
      channel_id: channel_id,
      id: id,
      reason: reason,
    }
  end

  def parse_type(
        @update_fail_malformed_htlc,
        <<channel_id::unsigned-big-size(256),
          id::unsigned-big-size(64),
          sha256_of_onion::bytes-size(32),
          failure_code::unsigned-big-size(16),
          >>) do
    %UpdateFailMalformedHtlcMsg{
      channel_id: channel_id,
      id: id,
      sha256_of_onion: sha256_of_onion,
      failure_code: failure_code,
    }
  end

  def parse_type(type, payload) do
    %UnknownMsg{type: type, payload: payload}
  end

  def encode(%InitMsg{} = msg) do
    gflen = byte_size(msg.global_features)
    lflen = byte_size(msg.local_features)
    <<
      @init::unsigned-big-size(16),
      gflen::unsigned-big-size(16), msg.global_features::bytes-size(gflen), 
      lflen::unsigned-big-size(16), msg.local_features::bytes-size(lflen)
    >>
  end

  def encode(%ErrorMsg{} = msg) do
    data_len = byte_size(msg.data)
    <<
      @error::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256), 
      data_len::unsigned-big-size(16), 
      msg.data::bytes-size(data_len)
    >>
  end

  def encode(%PingMsg{} = msg) do
    ignore_len = msg.ping_bytes * 8
    <<
      @ping::unsigned-big-size(16),
      msg.pong_bytes::unsigned-big-size(16),
      msg.ping_bytes::unsigned-big-size(16),
      0::size(ignore_len)
    >>
  end

  def encode(%PongMsg{} = msg) do
    ignore_len = msg.pong_bytes * 8
    <<
      @pong::unsigned-big-size(16),
      msg.pong_bytes::unsigned-big-size(16), 
      0::size(ignore_len)
    >>
  end

  def encode(%OpenChannelMsg{} = msg) do
    <<
      @open_channel::unsigned-big-size(16),
      msg.chain_hash::unsigned-big-size(256),
      msg.temporary_channel_id::unsigned-big-size(256),
      msg.funding_satoshis::unsigned-big-size(64),
      msg.push_msat::unsigned-big-size(64),
      msg.dust_limit_satoshis::unsigned-big-size(64),
      msg.max_htlc_value_in_flight_msat::unsigned-big-size(64),
      msg.channel_reserve_satoshis::unsigned-big-size(64),
      msg.htlc_minimum_msat::unsigned-big-size(64),
      msg.feerate_per_kw::unsigned-big-size(32),
      msg.to_self_delay::unsigned-big-size(16),
      msg.max_accepted_htlcs::unsigned-big-size(16),
      msg.funding_pubkey::bytes-size(33),
      msg.revocation_basepoint::bytes-size(33),
      msg.payment_basepoint::bytes-size(33),
      msg.delayed_payment_basepoint::bytes-size(33),
      msg.htlc_basepoint::bytes-size(33),
      msg.first_per_commitment_point::bytes-size(33),
      msg.channel_flags,
    >>
  end

  def encode(%AcceptChannelMsg{} = msg) do
    <<
      @accept_channel::unsigned-big-size(16),
      msg.temporary_channel_id::unsigned-big-size(256),
      msg.dust_limit_satoshis::unsigned-big-size(64),
      msg.max_htlc_value_in_flight_msat::unsigned-big-size(64),
      msg.channel_reserve_satoshis::unsigned-big-size(64),
      msg.htlc_minimum_msat::unsigned-big-size(64),
      msg.minimum_depth::unsigned-big-size(32),
      msg.to_self_delay::unsigned-big-size(16),
      msg.max_accepted_htlcs::unsigned-big-size(16),
      msg.funding_pubkey::bytes-size(33),
      msg.revocation_basepoint::bytes-size(33),
      msg.payment_basepoint::bytes-size(33),
      msg.delayed_payment_basepoint::bytes-size(33),
      msg.htlc_basepoint::bytes-size(33),
      msg.first_per_commitment_point::bytes-size(33),
    >>
  end

  def encode(%FundingCreatedMsg{} = msg) do
    <<
      @funding_created::unsigned-big-size(16),
      msg.temporary_channel_id::unsigned-big-size(256),
      msg.funding_txid::unsigned-big-size(256),
      msg.funding_output_index::unsigned-big-size(16),
      msg.signature::bytes-size(64)
    >>
  end

  def encode(%FundingSignedMsg{} = msg) do
    <<
      @funding_signed::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256),
      msg.signature::bytes-size(64)
    >>
  end

  def encode(%FundingLockedMsg{} = msg) do
    <<
      @funding_locked::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256),
      msg.next_per_commitment_point::bytes-size(33)
    >>
  end

  def encode(%ShutdownMsg{} = msg) do
    len = byte_size(msg.scriptpubkey)
    <<
      @shutdown::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256),
      len::unsigned-big-size(16),
      msg.scriptpubkey::bytes(),
    >>
  end

  def encode(%ClosingSignedMsg{} = msg) do
    <<
      @closing_signed::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256),
      msg.fee_satoshi::unsigned-big-size(64),
      msg.signature::bytes(),
    >>
  end

  def encode(%UpdateAddHtlcMsg{} = msg) do
    <<
      @update_add_htlc::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256),
      msg.id::unsigned-big-size(64),
      msg.amount_msat::unsigned-big-size(64),
      msg.payment_hash::bytes(),
      msg.cltv_expiry::unsigned-big-size(32),
      msg.onion_routing_packet::bytes(),
    >>
  end

  def encode(%UpdateAddHtlcMsg{} = msg) do
    <<
      @update_fulfill_htlc::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256),
      msg.id::unsigned-big-size(64),
      msg.payment_preimage::bytes(),
    >>
  end

  def encode(%UpdateFulfillHtlcMsg{} = msg) do
    <<
      @update_fulfill_htlc::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256),
      msg.id::unsigned-big-size(64),
      msg.payment_preimage::bytes(),
    >>
  end

  def encode(%UpdateFailHtlcMsg{} = msg) do
    <<
      @update_fail_htlc::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256),
      msg.id::unsigned-big-size(64),
      byte_size(msg.reason)::unsigned-big-size(16),
      msg.reason::bytes()
    >>
  end

  def encode(%UpdateFailMalformedHtlcMsg{} = msg) do
    <<
      @update_fail_malformed_htlc::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256),
      msg.id::unsigned-big-size(64),
      msg.sha256_of_onion::bytes(),
      msg.failure_code::unsigned-big-size(16),
    >>
  end

end
