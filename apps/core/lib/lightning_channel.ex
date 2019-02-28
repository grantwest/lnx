defmodule Volta.Core.LightningChannel do
  alias Volta.LightningMsg.OpenChannelMsg
  alias Volta.LightningMsg.AcceptChannelMsg
  alias Volta.LightningMsg.FundingCreatedMsg
  alias Volta.LightningMsg.FundingSignedMsg
  alias Volta.LightningMsg.FundingLockedMsg

  defmodule OpenChannelOpts do
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

      :remote_dust_limit_satoshis_range,
      :remote_max_htlc_value_in_flight_range,
      :remote_channel_reserve_satoshis_range,
      :remote_htlc_minimum_msat_range,
      :remote_minimum_depth_range,
      :remote_to_self_delay_range,
      :remote_max_accepted_htlcs_range,
    ]
  end

  defmodule AcceptChannelOpts do
    defstruct [
      :dust_limit_satoshis,
      :max_htlc_value_in_flight_msat,
      :channel_reserve_satoshis,
      :htlc_minimum_msat,
      :minimum_depth,
      :to_self_delay,
      :max_accepted_htlcs,
      :funding_pubkey,

      :allowable_chain_hashes,
      :remote_funding_satoshis_range,
      :remote_push_msat_range,
      :remote_dust_limit_satoshis_range,
      :remote_max_htlc_value_in_flight_range,
      :remote_channel_reserve_satoshis_range,
      :remote_htlc_minimum_msat_range,
      :remote_feerate_per_kw_range,
      :remote_to_self_delay_range,
      :remote_max_accepted_htlcs_range,
    ]
  end

  def create(:funder, %OpenChannelOpts{} = opts) do
    %{
      opts: opts,
      role: :funder,
      state: :wait_open_ch,
      channel_id: opts.temporary_channel_id,
    }
  end

  def create(:fundee, %AcceptChannelOpts{} = opts) do
    %{
      opts: opts,
      role: :fundee,
      state: :wait_open_ch,
    }
  end

  def open(%{state: :wait_open_ch} = ch) do
    {:ok, %{ch | state: :wait_accept_ch}, open_msg(ch)}
  end

  def receive(%{state: :wait_open_ch} = ch, %OpenChannelMsg{} = msg) do
    {:ok, %{ch | state: :wait_funding_created}, accept_msg(ch)}
  end

  def receive(%{state: :wait_accept_ch} = ch, %AcceptChannelMsg{} = msg) do
    to_send = funding_created_msg(ch)
    ch = %{ch | state: :wait_funding_signed}
    {:ok, ch, to_send}
  end 

  def receive(%{state: :wait_funding_created} = ch, %FundingCreatedMsg{} = msg) do
    to_send = funding_signed_msg(ch)
    ch = %{ch | state: :wait_funding_locked}
    {:ok, ch, to_send}
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

  defp open_msg(%{opts: opts, channel_id: ch_id}) do
    %OpenChannelMsg{
      chain_hash: opts.chain_hash,
      temporary_channel_id: ch_id,
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
  end

  defp accept_msg(%{channel_id: ch_id}) do
    %AcceptChannelMsg{
      temporary_channel_id: ch_id,
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
  end

  defp funding_created_msg(%{channel_id: ch_id}) do
    %FundingCreatedMsg{
      temporary_channel_id: ch_id,
      funding_txid: 0,
      funding_output_index: 0,
      signature: 0,
    }
  end

  defp funding_signed_msg(ch) do
    %FundingSignedMsg{
      channel_id: ch[:channel_id],
      signature: 0,
    }
  end

end
