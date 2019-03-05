defmodule Volta.Core.LightningChannelTest do
  use ExUnit.Case, async: true
  alias Volta.KeyUtils
  alias Volta.Core.LightningChannel
  alias Volta.Core.LightningChannel.OpenChannelOpts
  alias Volta.Core.LightningChannel.AcceptChannelOpts
  alias Volta.LightningMsg.OpenChannelMsg
  alias Volta.LightningMsg.AcceptChannelMsg
  alias Volta.LightningMsg.FundingCreatedMsg
  alias Volta.LightningMsg.FundingSignedMsg
  alias Volta.LightningMsg.FundingLockedMsg

  defp scenario_a() do 
    %{
      open_ch_opts: %OpenChannelOpts{
        chain_hash: 1234,
        temporary_channel_id: 1,
        funding_satoshis: 3_000_000,
        push_msat: 4000,
        dust_limit_satoshis: 5000,
        max_htlc_value_in_flight_msat: 600_000_000,
        channel_reserve_satoshis: 7000,
        htlc_minimum_msat: 8000,
        feerate_per_kw: 10,
        to_self_delay: 11,
        max_accepted_htlcs: 12,
        funding_pubkey: "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
      },
      accept_ch_opts: %AcceptChannelOpts{
        dust_limit_satoshis: 500,
        max_htlc_value_in_flight_msat: 60_000_000,
        channel_reserve_satoshis: 700,
        htlc_minimum_msat: 800,
        minimum_depth: 13,
        to_self_delay: 14,
        max_accepted_htlcs: 15,
        funding_pubkey: "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
      },
      open_msg: %OpenChannelMsg{
        chain_hash: 1234,
        temporary_channel_id: 1,
        funding_satoshis: 3_000_000,
        push_msat: 4000,
        dust_limit_satoshis: 5000,
        max_htlc_value_in_flight_msat: 600_000_000,
        channel_reserve_satoshis: 7000,
        htlc_minimum_msat: 8000,
        feerate_per_kw: 10,
        to_self_delay: 11,
        max_accepted_htlcs: 12,
        funding_pubkey: "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
        revocation_basepoint: "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
        payment_basepoint: "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
        delayed_payment_basepoint: "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
        htlc_basepoint: "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
        first_per_commitment_point: "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
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
        funding_txid: 2,
        funding_output_index: 0,
        signature: 0,
      },

      funding_signed_msg: %FundingSignedMsg{
        channel_id: 2,
        signature: 0,
      },

      funding_locked_msg_a: %FundingLockedMsg{
        channel_id: 2,
        next_per_commitment_point: 0,
      },

      funding_locked_msg_b: %FundingLockedMsg{
        channel_id: 2,
        next_per_commitment_point: 0,
      }
    }
  end

  test "open channel as initiator/funder/A" do
    data = scenario_a()

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
    data = scenario_a()

    ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:open_msg])
    assert to_send == data[:accept_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:funding_created_msg])
    assert to_send == data[:funding_signed_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:funding_locked_msg_a])
    assert to_send == data[:funding_locked_msg_b]
  end

  test "do not accept if funding < push" do
    data = scenario_a()
    open_msg = %{data[:open_msg] | funding_satoshis: 3_000_000, push_msat: 3_000_000_001}

    ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
    {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
    assert error_msg == "push (3000000001 msat) cannot be greater than funding (3000000 sat)"
  end

  test "do not accept if to self delay is too large" do
    data = scenario_a()
    open_msg = %{data[:open_msg] | to_self_delay: 26299}

    ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
    {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
    assert error_msg == "to_self_delay (26299 blocks) is too large"
  end

  test "do not accept if max_accepted_htlcs > 483" do
    data = scenario_a()
    open_msg = %{data[:open_msg] | max_accepted_htlcs: 484}

    ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
    {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
    assert error_msg == "max_accepted_htlcs (484) cannot be greater than 483"
  end

  test "do not accept if dust limit > reserve" do
    data = scenario_a()
    open_msg = %{data[:open_msg] | dust_limit_satoshis: 7001, channel_reserve_satoshis: 7000}

    ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
    {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
    assert error_msg == "dust limit (7001 sat) cannot be greater than reserve (7000 sat)"
  end

  test "do not accept if any of the pub keys or base points are not valid public keys" do
    data = scenario_a()
    ch = LightningChannel.create(:fundee, data[:accept_ch_opts])

    open_msg = %{data[:open_msg] | funding_pubkey: <<0, 1, 2>>}
    {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
    assert error_msg == "funding_pubkey (<<0, 1, 2>>) is not a valid public key"

    open_msg = %{data[:open_msg] | revocation_basepoint: <<0, 1, 2>>}
    {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
    assert error_msg == "revocation_basepoint (<<0, 1, 2>>) is not a valid public key"

    open_msg = %{data[:open_msg] | payment_basepoint: <<0, 1, 2>>}
    {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
    assert error_msg == "payment_basepoint (<<0, 1, 2>>) is not a valid public key"

    open_msg = %{data[:open_msg] | delayed_payment_basepoint: <<0, 1, 2>>}
    {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
    assert error_msg == "delayed_payment_basepoint (<<0, 1, 2>>) is not a valid public key"

    open_msg = %{data[:open_msg] | htlc_basepoint: <<0, 1, 2>>}
    {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
    assert error_msg == "htlc_basepoint (<<0, 1, 2>>) is not a valid public key"

    open_msg = %{data[:open_msg] | first_per_commitment_point: <<0, 1, 2>>}
    {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
    assert error_msg == "first_per_commitment_point (<<0, 1, 2>>) is not a valid public key"
  end


  defp hex(nil), do: nil
  defp hex(b) do
    Base.encode16(b, case: :lower)
  end

  defp bin(h) do
    Base.decode16!(h, case: :lower)
  end

  defp pubkey(k), do: k |> bin() |> KeyUtils.decompress()

end
