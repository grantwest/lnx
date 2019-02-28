defmodule Volta.Core.LightningChannelTest do
  use ExUnit.Case, async: true
  alias Volta.Core.LightningChannel
  alias Volta.Core.LightningChannel.OpenChannelOpts
  alias Volta.Core.LightningChannel.AcceptChannelOpts
  alias Volta.LightningMsg.OpenChannelMsg
  alias Volta.LightningMsg.AcceptChannelMsg
  alias Volta.LightningMsg.FundingCreatedMsg
  alias Volta.LightningMsg.FundingSignedMsg
  alias Volta.LightningMsg.FundingLockedMsg

  @data %{
    scenario_a: %{
      open_ch_opts: %OpenChannelOpts{
        chain_hash: 1234,
        temporary_channel_id: 1,
        funding_satoshis: 0,
        push_msat: 0,
        dust_limit_satoshis: 0,
        max_htlc_value_in_flight_msat: 0,
        channel_reserve_satoshis: 0,
        htlc_minimum_msat: 0,
        feerate_per_kw: 0,
        to_self_delay: 0,
        max_accepted_htlcs: 0,
        funding_pubkey: 0,
        remote_dust_limit_satoshis_range: 0,
        remote_max_htlc_value_in_flight_range: 0,
        remote_channel_reserve_satoshis_range: 0,
        remote_htlc_minimum_msat_range: 0,
        remote_minimum_depth_range: 0,
        remote_to_self_delay_range: 0,
        remote_max_accepted_htlcs_range: 0,
      },
      accept_ch_opts: %AcceptChannelOpts{
        dust_limit_satoshis: 0,
        max_htlc_value_in_flight_msat: 0,
        channel_reserve_satoshis: 0,
        htlc_minimum_msat: 0,
        minimum_depth: 0,
        to_self_delay: 0,
        max_accepted_htlcs: 0,
        funding_pubkey: 0,
        allowable_chain_hashes: 0,
        remote_funding_satoshis_range: 0,
        remote_push_msat_range: 0,
        remote_dust_limit_satoshis_range: 0,
        remote_max_htlc_value_in_flight_range: 0,
        remote_channel_reserve_satoshis_range: 0,
        remote_htlc_minimum_msat_range: 0,
        remote_feerate_per_kw_range: 0,
        remote_to_self_delay_range: 0,
        remote_max_accepted_htlcs_range: 0,
      },
      open_msg: %OpenChannelMsg{
        chain_hash: 1234,
        temporary_channel_id: 1,
        funding_satoshis: 0,
        push_msat: 0,
        dust_limit_satoshis: 0,
        max_htlc_value_in_flight_msat: 0,
        channel_reserve_satoshis: 0,
        htlc_minimum_msat: 0,
        feerate_per_kw: 0,
        to_self_delay: 0,
        max_accepted_htlcs: 0,
        funding_pubkey: 0,
        revocation_basepoint: 0,
        payment_basepoint: 0,
        delayed_payment_basepoint: 0,
        htlc_basepoint: 0,
        first_per_commitment_point: 0,
        channel_flags: 0,
        shutdown_scriptpubkey: 0,
      },

      accept_msg: %AcceptChannelMsg{
        temporary_channel_id: 1,
        dust_limit_satoshis: 0,
        max_htlc_value_in_flight_msat: 0,
        channel_reserve_satoshis: 0,
        htlc_minimum_msat: 0,
        minimum_depth: 0,
        to_self_delay: 0,
        max_accepted_htlcs: 0,
        funding_pubkey: 0,
        revocation_basepoint: 0,
        payment_basepoint: 0,
        delayed_payment_basepoint: 0,
        htlc_basepoint: 0,
        first_per_commitment_point: 0,
        shutdown_scriptpubkey: 0,
      },

      funding_created_msg: %FundingCreatedMsg{
        temporary_channel_id: 1,
        funding_txid: 0,
        funding_output_index: 0,
        signature: 0,
      },

      funding_signed_msg: %FundingSignedMsg{
        channel_id: 1,
        signature: 0,
      },

      funding_locked_msg_a: %FundingLockedMsg{
        channel_id: 1,
        next_per_commitment_point: 0,
      },

      funding_locked_msg_b: %FundingLockedMsg{
        channel_id: 1,
        next_per_commitment_point: 1,
      }
    }
  }

  test "open channel as initiator/funder/A" do
    data = @data[:scenario_a]

    ch = LightningChannel.create(:funder, data[:open_ch_opts])
    {:ok, ch, to_send} = LightningChannel.open(ch)
    assert to_send == data[:open_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:accept_msg])
    assert to_send == data[:funding_created_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:funding_signed_msg])
    assert to_send == data[:funding_locked_msg_a]
    {:ok, ch}      = LightningChannel.receive(ch, data[:funding_locked_msg_b])
  end

  test "open channel as responder/fundee/B" do
    data = @data[:scenario_a]

    ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:open_msg])
    assert to_send == data[:accept_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:funding_created_msg])
    assert to_send == data[:funding_signed_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:funding_locked_msg_a])
    assert to_send == data[:funding_locked_msg_b]
  end  

end
