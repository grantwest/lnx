defmodule Volta.Core.LightningChannelTest do
  use ExUnit.Case, async: true
  alias Volta.Core.LightningChannel
  alias Volta.LightningMsg.OpenChannelMsg
  alias Volta.LightningMsg.AcceptChannelMsg
  alias Volta.LightningMsg.FundingCreatedMsg
  alias Volta.LightningMsg.FundingSignedMsg
  alias Volta.LightningMsg.FundingLockedMsg

  @msgs %{
    scenario_a: %{
      open_msg: %OpenChannelMsg{
        chain_hash: 0,
        temporary_channel_id: 0,
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
        temporary_channel_id: 0,
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
        temporary_channel_id: 0,
        funding_txid: 0,
        funding_output_index: 0,
        signature: 0,
      },

      funding_signed_msg: %FundingSignedMsg{
        channel_id: 0,
        signature: 0,
      },

      funding_locked_msg_a: %FundingLockedMsg{
        channel_id: 0,
        next_per_commitment_point: 0,
      },

      funding_locked_msg_b: %FundingLockedMsg{
        channel_id: 0,
        next_per_commitment_point: 0,
      }
    }
  }

  test "open channel as initiator/funder/A" do
    msgs = @msgs[:scenario_a]

    ch = LightningChannel.create(:funder)
    {:ok, ch, to_send} = LightningChannel.open(ch)
    assert to_send == msgs[:open_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, msgs[:accept_msg])
    assert to_send == msgs[:funding_created_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, msgs[:funding_signed_msg])
    assert to_send == msgs[:funding_locked_msg_a]
    {:ok, ch}      = LightningChannel.receive(ch, msgs[:funding_locked_msg_b])
  end

  test "open channel as responder/fundee/B" do
    msgs = @msgs[:scenario_a]

    ch = LightningChannel.create(:fundee)
    {:ok, ch, to_send} = LightningChannel.receive(ch, msgs[:open_msg])
    assert to_send == msgs[:accept_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, msgs[:funding_created_msg])
    assert to_send == msgs[:funding_signed_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, msgs[:funding_locked_msg_a])
    assert to_send = msgs[:funding_locked_msg_b]
  end  

end
