defmodule Volta.Core.LightningChannel do
  alias Volta.KeyUtils
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
    to_send = open_msg(ch)
    ch = %{ch | state: :wait_accept_ch}
    {:ok, ch, to_send}
  end

  def receive(%{state: :wait_open_ch} = ch, %OpenChannelMsg{} = msg) do
    case validate(ch, msg) do
      :valid -> 
        ch = Map.put(ch, :channel_id, msg.temporary_channel_id)
        ch = %{ch | state: :wait_funding_created}
        {:ok, ch, accept_msg(ch)}

      {:invalid, error_msg} -> {:reject, :invalid, error_msg}
    end
  end

  def receive(%{state: :wait_accept_ch} = ch, %AcceptChannelMsg{} = msg) do
    temp_ch_id = ch[:channel_id]
    ch = %{ch | channel_id: 2}
    to_send = funding_created_msg(ch, temp_ch_id)
    ch = %{ch | state: :wait_funding_signed}
    {:ok, ch, to_send}
  end 

  def receive(%{state: :wait_funding_created} = ch, %FundingCreatedMsg{} = msg) do
    ch = %{ch | channel_id: msg.funding_txid}
    to_send = funding_signed_msg(ch)
    ch = %{ch | state: :wait_funding_locked}
    {:ok, ch, to_send}
  end

  def receive(%{state: :wait_funding_signed} = ch, %FundingSignedMsg{} = msg) do
    to_send = funding_locked_msg(ch)
    ch = %{ch | state: :wait_funding_locked}
    {:ok, ch, to_send}
  end

  def receive(%{state: :wait_funding_locked, role: :fundee} = ch, %FundingLockedMsg{} = msg) do
    to_send = funding_locked_msg(ch)
    {:ok, ch, to_send}
  end

  def receive(%{state: :wait_funding_locked, role: :funder} = ch, %FundingLockedMsg{} = msg) do
    {:ok, ch}
  end

  defp open_msg(%{opts: opts, channel_id: ch_id}) do
    %OpenChannelMsg{
      chain_hash: opts.chain_hash,
      temporary_channel_id: ch_id,
      funding_satoshis: opts.funding_satoshis,
      push_msat: opts.push_msat,
      dust_limit_satoshis: opts.dust_limit_satoshis,
      max_htlc_value_in_flight_msat: opts.max_htlc_value_in_flight_msat,
      channel_reserve_satoshis: opts.channel_reserve_satoshis,
      htlc_minimum_msat: opts.htlc_minimum_msat,
      feerate_per_kw: opts.feerate_per_kw,
      to_self_delay: opts.to_self_delay,
      max_accepted_htlcs: opts.max_accepted_htlcs,
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

  defp funding_created_msg(%{channel_id: ch_id}, temp_ch_id) do
    %FundingCreatedMsg{
      temporary_channel_id: temp_ch_id,
      funding_txid: ch_id,
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

  defp funding_locked_msg(ch) do
    %FundingLockedMsg{
      channel_id: ch[:channel_id],
      next_per_commitment_point: 0,
    }
  end

  defp validate(ch, %OpenChannelMsg{} = msg) do
    cond do 
      msg.push_msat > 1000 * msg.funding_satoshis ->
        {:invalid, "push (#{msg.push_msat} msat) cannot be greater than funding (#{msg.funding_satoshis} sat)"}

      msg.to_self_delay > 26298 ->
        {:invalid, "to_self_delay (#{msg.to_self_delay} blocks) is too large"}
      
      msg.max_accepted_htlcs > 483 ->
        {:invalid, "max_accepted_htlcs (#{msg.max_accepted_htlcs}) cannot be greater than 483"}

      msg.dust_limit_satoshis > msg.channel_reserve_satoshis ->
        {:invalid, "dust limit (#{msg.dust_limit_satoshis} sat) cannot be greater than reserve (#{msg.channel_reserve_satoshis} sat)"}

      !KeyUtils.valid_public_key?(msg.funding_pubkey) ->
        {:invalid, "funding_pubkey (#{inspect(msg.funding_pubkey)}) is not a valid public key"}

      !KeyUtils.valid_public_key?(msg.revocation_basepoint) ->
        {:invalid, "revocation_basepoint (#{inspect(msg.revocation_basepoint)}) is not a valid public key"}

      !KeyUtils.valid_public_key?(msg.payment_basepoint) ->
        {:invalid, "payment_basepoint (#{inspect(msg.payment_basepoint)}) is not a valid public key"}

      !KeyUtils.valid_public_key?(msg.delayed_payment_basepoint) ->
        {:invalid, "delayed_payment_basepoint (#{inspect(msg.delayed_payment_basepoint)}) is not a valid public key"}

      !KeyUtils.valid_public_key?(msg.htlc_basepoint) ->
        {:invalid, "htlc_basepoint (#{inspect(msg.htlc_basepoint)}) is not a valid public key"}

      !KeyUtils.valid_public_key?(msg.first_per_commitment_point) ->
        {:invalid, "first_per_commitment_point (#{inspect(msg.first_per_commitment_point)}) is not a valid public key"}

      true -> :valid
    end
  end



end
