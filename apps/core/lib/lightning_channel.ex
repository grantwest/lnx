defmodule Volta.Core.LightningChannel do
  alias Volta.LightningMsg.OpenChannelMsg
  alias Volta.LightningMsg.AcceptChannelMsg
  alias Volta.LightningMsg.FundingCreatedMsg
  alias Volta.LightningMsg.FundingSignedMsg
  alias Volta.LightningMsg.FundingLockedMsg

  defmodule Settings do
    defstruct [
      :dust_limit_satoshis,
      :max_htlc_value_in_flight_msat,
      :channel_reserve_satoshis,
      :htlc_minimum_msat,
      :minimum_depth,
      :to_self_delay,
      :max_accepted_htlcs,
    ]
  end

  def create(:funder) do
    %{
      # local_settings: local_settings,
      role: :funder,
      state: :wait_open_ch,
    }
  end

  def create(:fundee) do
    %{
      # local_settings: local_settings,
      role: :fundee,
      state: :wait_open_ch,
    }
  end

  def open(%{state: :wait_open_ch} = ch) do
    open_msg = %OpenChannelMsg{
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
    }
    ch = %{ch | state: :wait_accept_ch}
    {:ok, ch, open_msg}
  end

  def receive(%{state: :wait_open_ch} = ch, %OpenChannelMsg{} = msg) do
    accept_msg = %AcceptChannelMsg{
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
    }
    ch = %{ch | state: :wait_funding_created}
    {:ok, ch, accept_msg}
  end

  def receive(%{state: :wait_accept_ch} = ch, %AcceptChannelMsg{} = msg) do
    funding_created_msg = %FundingCreatedMsg{
      temporary_channel_id: 0,
      funding_txid: 0,
      funding_output_index: 0,
      signature: 0,
    }
    ch = %{ch | state: :wait_funding_signed}
    {:ok, ch, funding_created_msg}
  end 

  def receive(%{state: :wait_funding_created} = ch, %FundingCreatedMsg{} = msg) do
    funding_signed_msg = %FundingSignedMsg{
      channel_id: 0,
      signature: 0,
    }
    ch = %{ch | state: :wait_funding_locked}
    {:ok, ch, funding_signed_msg}
  end

  def receive(%{state: :wait_funding_signed} = ch, %FundingSignedMsg{} = msg) do
    funding_locked_msg = %FundingLockedMsg{
      channel_id: 0,
      next_per_commitment_point: 0,
    }
    ch = %{ch | state: :wait_funding_locked}
    {:ok, ch, funding_locked_msg}
  end

  def receive(%{state: :wait_funding_locked, role: :fundee} = ch, %FundingLockedMsg{} = msg) do
    funding_locked_msg = %FundingLockedMsg{
      channel_id: 1,
      next_per_commitment_point: 1,
    }
    {:ok, ch, funding_locked_msg}
  end

  def receive(%{state: :wait_funding_locked, role: :funder} = ch, %FundingLockedMsg{} = msg) do
    {:ok, ch}
  end

end
