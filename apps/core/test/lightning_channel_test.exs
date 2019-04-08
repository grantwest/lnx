defmodule Volta.Core.LightningChannelTest do
  use ExUnit.Case, async: true
  alias Volta.KeyUtils
  alias Volta.Core.CommitmentSecrets
  alias Volta.Core.LightningChannel
  alias Volta.Core.LightningChannel.OpenChannelOpts
  alias Volta.Core.LightningChannel.AcceptChannelOpts
  alias Volta.LightningMsg.OpenChannelMsg
  alias Volta.LightningMsg.AcceptChannelMsg
  alias Volta.LightningMsg.FundingCreatedMsg
  alias Volta.LightningMsg.FundingSignedMsg
  alias Volta.LightningMsg.FundingLockedMsg
  alias Volta.LightningMsg.ShutdownMsg
  alias Volta.LightningMsg.ClosingSignedMsg
  alias Volta.LightningMsg.UpdateAddHtlcMsg


  # key 1: %{
  #   priv: "044f1bf1504cae9a0c7d7e6f59673c23f32c20e1ff28be575132e770e00942e0",
  #   pub: "0253a6e35088a00b77e4490fef3065a16d9b455dbed71c1b961e2b26d1f93f54d6"
  # }
  # key 2: %{
  #   priv: "8575873f893e2fcae6ec70b106b2f21b8399ae3e5310c757598ec577bf3628b8",
  #   pub: "03d3d071cf8941db441ddd5487317d19b8495d5b36adb28502f7d2056bc312576f"
  # }
  # key 3: %{
  #   priv: "b4f43c6f3d2e8d1fc5e7137698a6423a46366d53816444ab24189a0cdaaf4037",
  #   pub: "02ca92ef00e70fb9bc86c40f6441554261bb37243218d934b62ae60a12c7097981"
  # }
  # key 4: %{
  #   priv: "3b2a796700dbfdff2e60b95adc67dcf78b57600a0fd92c8b1841acdf6dfa537a",
  #   pub: "0365d152a0850b7eb88d47716495f3b59929d53157e7d2562bbd2bf0ecabaae7be"
  # }
  # key 5: %{
  #   priv: "ccfe21106afc84c653aeb559af9df8fab7ef81d352f50095a4c21b92fa2bbca7",
  #   pub: "024136ffb77726d468f8f760bf8d7b7f36b50795a1a282249faef0f01644ce2c0b"
  # }
  # key 6: %{
  #   priv: "30b2eb67ff4a4f30a6a3e7f20a2e8917d6c25851d959f376500035940be796bc",
  #   pub: "02ce71b0719e4568f2c14072f356ecd9214531768f283c32c52ae05fd0e4f19d47"
  # }
  # key 7: %{
  #   priv: "4085c1c911e43ed754df03db6ca398809460d3b24f96982af77c7099c3591c94",
  #   pub: "02424eceed314ace5d2a0a87fc25d739cddfc00d9ad98e37d5a3e2f87647f4ff03"
  # }
  # key 8: %{
  #   priv: "f8bdfdbe57ebbe070c9e2c36d7dbef9ac4ce13f6fe2c2057323b2a41a7e51124",
  #   pub: "02cca024f40f7ea34b055d47a3e7ae169788dcfa1a31806bb7ec080b76b580e061"
  # }
  # key 9: %{
  #   priv: "15688099525b5a8ced776fddfd56566596bde784848ccaa2ae11b7a017e90c16",
  #   pub: "03b4c2bb737ea2652e664581374f18c9e19363d2803c78a930095024e3451aeb29"
  # }
  # key 10: %{
  #   priv: "ecec0e80697c44a1fe7266c61fca304f9c251d7aa7ff114b1251ff5d9ffc3e3f",
  #   pub: "034183eb7d6b3dff95618aab3a7db4485513213e77091233702c68e3d1f2bd2df2"
  # }
  # key 11: %{
  #   priv: "1bae727dd881a913b0bde101727546dbf3d736df2a5e6816e758029fc77527e7",
  #   pub: "032ce171ecb7ee9392d9e2776ed0d14c7a67c1a8c9ca73680396bc93909b94ae09"
  # }
  # key 12: %{
  #   priv: "3101834a1f81c6e7c618b3c249587d89fedcd284f2a024063472c454da19a1d7",
  #   pub: "0222c3f7f4f462b898d7787c24454c912de761c78fdd45be2e83510244d951528f"
  # }


  defp scenario_a() do 
    initiator_commitment_seed = bin("30b2eb67ff4a4f30a6a3e7f20a2e8917d6c25851d959f376500035940be796bc")
    initiator_commitment_secret = CommitmentSecrets.commitment(initiator_commitment_seed, CommitmentSecrets.starting_index())

    responder_commitment_seed = bin("3101834a1f81c6e7c618b3c249587d89fedcd284f2a024063472c454da19a1d7")
    responder_commitment_secret = CommitmentSecrets.commitment(responder_commitment_seed, CommitmentSecrets.starting_index())

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
        funding_pubkey:            pubkey("0253a6e35088a00b77e4490fef3065a16d9b455dbed71c1b961e2b26d1f93f54d6"),
        revocation_basepoint:      pubkey("03d3d071cf8941db441ddd5487317d19b8495d5b36adb28502f7d2056bc312576f"),
        payment_basepoint:         pubkey("02ca92ef00e70fb9bc86c40f6441554261bb37243218d934b62ae60a12c7097981"),
        delayed_payment_basepoint: pubkey("0365d152a0850b7eb88d47716495f3b59929d53157e7d2562bbd2bf0ecabaae7be"),
        htlc_basepoint:            pubkey("024136ffb77726d468f8f760bf8d7b7f36b50795a1a282249faef0f01644ce2c0b"),
        commitment_seed: initiator_commitment_seed,
        shutdown_scriptpubkey: <<8, 7, 6, 5>>,
      },
      accept_ch_opts: %AcceptChannelOpts{
        dust_limit_satoshis: 500,
        max_htlc_value_in_flight_msat: 60_000_000,
        channel_reserve_satoshis: 700,
        htlc_minimum_msat: 800,
        minimum_depth: 13,
        to_self_delay: 14,
        max_accepted_htlcs: 15,
        funding_pubkey:            pubkey("02424eceed314ace5d2a0a87fc25d739cddfc00d9ad98e37d5a3e2f87647f4ff03"),
        revocation_basepoint:      pubkey("02cca024f40f7ea34b055d47a3e7ae169788dcfa1a31806bb7ec080b76b580e061"),
        payment_basepoint:         pubkey("03b4c2bb737ea2652e664581374f18c9e19363d2803c78a930095024e3451aeb29"),
        delayed_payment_basepoint: pubkey("034183eb7d6b3dff95618aab3a7db4485513213e77091233702c68e3d1f2bd2df2"),
        htlc_basepoint:            pubkey("032ce171ecb7ee9392d9e2776ed0d14c7a67c1a8c9ca73680396bc93909b94ae09"),
        commitment_seed: responder_commitment_seed,
        shutdown_scriptpubkey: <<4, 3, 2, 1>>,
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
        funding_pubkey:            pubkey("0253a6e35088a00b77e4490fef3065a16d9b455dbed71c1b961e2b26d1f93f54d6"),
        revocation_basepoint:      pubkey("03d3d071cf8941db441ddd5487317d19b8495d5b36adb28502f7d2056bc312576f"),
        payment_basepoint:         pubkey("02ca92ef00e70fb9bc86c40f6441554261bb37243218d934b62ae60a12c7097981"),
        delayed_payment_basepoint: pubkey("0365d152a0850b7eb88d47716495f3b59929d53157e7d2562bbd2bf0ecabaae7be"),
        htlc_basepoint:            pubkey("024136ffb77726d468f8f760bf8d7b7f36b50795a1a282249faef0f01644ce2c0b"),
        first_per_commitment_point: KeyUtils.pub_from_priv(initiator_commitment_secret),
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
        funding_pubkey:            pubkey("02424eceed314ace5d2a0a87fc25d739cddfc00d9ad98e37d5a3e2f87647f4ff03"),
        revocation_basepoint:      pubkey("02cca024f40f7ea34b055d47a3e7ae169788dcfa1a31806bb7ec080b76b580e061"),
        payment_basepoint:         pubkey("03b4c2bb737ea2652e664581374f18c9e19363d2803c78a930095024e3451aeb29"),
        delayed_payment_basepoint: pubkey("034183eb7d6b3dff95618aab3a7db4485513213e77091233702c68e3d1f2bd2df2"),
        htlc_basepoint:            pubkey("032ce171ecb7ee9392d9e2776ed0d14c7a67c1a8c9ca73680396bc93909b94ae09"),
        first_per_commitment_point: KeyUtils.pub_from_priv(responder_commitment_secret),
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
      },

      shutdown_msg_funder: %ShutdownMsg{
        channel_id: 2,
        scriptpubkey: <<8, 7, 6, 5>>,
      },

      shutdown_msg_fundee: %ShutdownMsg{
        channel_id: 2,
        scriptpubkey: <<4, 3, 2, 1>>,
      },

      update_add_htlc_0: %UpdateAddHtlcMsg{
        channel_id: 2,
        id: 0,
        amount_msat: 101,
        payment_hash: bin("04e2e68ff86e836c4760af195a7fd398e3f18a0d1af401ec95fe677d62726328"),
        cltv_expiry: 1000,
        onion_routing_packet: <<>>,
      },

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
    {:ok, _ch}         = LightningChannel.receive(ch, data[:funding_locked_msg_b])
  end

  test "open channel as responder/fundee/B" do
    data = scenario_a()

    ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:open_msg])
    assert to_send == data[:accept_msg]
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:funding_created_msg])
    assert to_send == data[:funding_signed_msg]
    {:ok, _ch, to_send} = LightningChannel.receive(ch, data[:funding_locked_msg_a])
    assert to_send == data[:funding_locked_msg_b]
  end

  test "initiate close as channel funder" do
    data = scenario_a()

    # Get channel into normal open state
    ch = LightningChannel.create(:funder, data[:open_ch_opts])
    {:ok, ch, _} = LightningChannel.open(ch)
    {:ok, ch, _} = LightningChannel.receive(ch, data[:accept_msg])
    {:ok, ch, _} = LightningChannel.receive(ch, data[:funding_signed_msg])
    {:ok, ch}    = LightningChannel.receive(ch, data[:funding_locked_msg_b])

    # close channel test
    {:ok, ch, to_send} = LightningChannel.close(ch)
    assert to_send == data[:shutdown_msg_funder]
    {:ok, _ch} =         LightningChannel.receive(ch, data[:shutdown_msg_fundee])
  end

  test "respond to close as channel funder" do
    data = scenario_a()

    # Get channel into normal open state
    ch = LightningChannel.create(:funder, data[:open_ch_opts])
    {:ok, ch, _} = LightningChannel.open(ch)
    {:ok, ch, _} = LightningChannel.receive(ch, data[:accept_msg])
    {:ok, ch, _} = LightningChannel.receive(ch, data[:funding_signed_msg])
    {:ok, ch}    = LightningChannel.receive(ch, data[:funding_locked_msg_b])

    # close channel test
    {:ok, _ch, to_send} = LightningChannel.receive(ch, data[:shutdown_msg_fundee])
    assert to_send == data[:shutdown_msg_funder]
  end

  test "initiate close as channel fundee" do
    data = scenario_a()

    # Get channel into normal open state
    ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
    {:ok, ch, _} = LightningChannel.receive(ch, data[:open_msg])
    {:ok, ch, _} = LightningChannel.receive(ch, data[:funding_created_msg])
    {:ok, ch, _} = LightningChannel.receive(ch, data[:funding_locked_msg_a])

    # close channel test
    {:ok, ch, to_send} = LightningChannel.close(ch)
    assert to_send == data[:shutdown_msg_fundee]
    {:ok, _ch} = LightningChannel.receive(ch, data[:shutdown_msg_funder])
  end

  test "respond to close as channel fundee" do
    data = scenario_a()

    # Get channel into normal open state
    ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
    {:ok, ch, _} = LightningChannel.receive(ch, data[:open_msg])
    {:ok, ch, _} = LightningChannel.receive(ch, data[:funding_created_msg])
    {:ok, ch, _} = LightningChannel.receive(ch, data[:funding_locked_msg_a])

    # close channel test
    {:ok, _ch, to_send} = LightningChannel.receive(ch, data[:shutdown_msg_funder])
    assert to_send == data[:shutdown_msg_fundee]
  end

  test "receive htlc as funder" do
    data = scenario_a()

    # Get channel into normal open state
    ch = LightningChannel.create(:funder, data[:open_ch_opts])
    {:ok, ch, _} = LightningChannel.open(ch)
    {:ok, ch, _} = LightningChannel.receive(ch, data[:accept_msg])
    {:ok, ch, _} = LightningChannel.receive(ch, data[:funding_signed_msg])
    {:ok, ch}    = LightningChannel.receive(ch, data[:funding_locked_msg_b])

    # Receive HTLC
    {:ok, ch, to_send} = LightningChannel.receive(ch, data[:])

  end

  describe "reject OpenChannelMsg if" do
    test "push_msat > funding_satoshis * 1000" do
      data = scenario_a()
      open_msg = %{data[:open_msg] | funding_satoshis: 3_000_000, push_msat: 3_000_000_001}

      ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
      {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
      assert error_msg == "push (3000000001 msat) cannot be greater than funding (3000000 sat)"
    end

    test "to_self_delay is unreasonably large" do
      data = scenario_a()
      open_msg = %{data[:open_msg] | to_self_delay: 26299}

      ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
      {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
      assert error_msg == "to_self_delay (26299 blocks) is too large"
    end

    test "max_accepted_htlcs > 483" do
      data = scenario_a()
      open_msg = %{data[:open_msg] | max_accepted_htlcs: 484}

      ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
      {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
      assert error_msg == "max_accepted_htlcs (484) cannot be greater than 483"
    end

    test "any of the pub keys or base points are not valid public keys" do
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

    test "dustlimit > reserve" do
      data = scenario_a()
      open_msg = %{data[:open_msg] | dust_limit_satoshis: 7001, channel_reserve_satoshis: 7000}

      ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
      {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
      assert error_msg == "dust limit (7001 sat) cannot be greater than reserve (7000 sat)"
    end

  end

  describe "reject AcceptChannelMsg if" do
    test "channel_reserve_satoshis < dust_limit_satoshis of OpenChannelMsg" do
      data = scenario_a()
      open_msg = %{data[:open_msg] | funding_satoshis: 3_000_000, push_msat: 3_000_000_001}

      ch = LightningChannel.create(:fundee, data[:accept_ch_opts])
      {:reject, :invalid, error_msg} = LightningChannel.receive(ch, open_msg)
      assert error_msg == "push (3000000001 msat) cannot be greater than funding (3000000 sat)"
    end

    test "channel_reserve_satoshis from the open_channel message is less than dust_limit_satoshis" do
      
    end

    test "to_self_delay is unreasonably large" do
      
    end

    test "max_accepted_htlcs > 483" do
      
    end

    test "any of the pub keys or base points are not valid public keys" do
      
    end

    test "dustlimit > reserve" do
      
    end

    # test "" do
      
    # end

    # test "" do
      
    # end

    # test "" do
      
    # end

    # test "" do
      
    # end

    # test "" do
      
    # end

    
  end

  # test "asdf" do
  #   for i <- 1..12 do
  #     {pub, priv} = :crypto.generate_key(:ecdh, :secp256k1)
  #     key = %{pub: hex(Volta.KeyUtils.compress(pub)), priv: hex(priv)}
  #     IO.inspect(key, label: "key #{i}")
  #   end
  # end

#   pair: {<<4, 212, 78, 91, 189, 193, 212, 19, 250, 97, 147, 136, 154, 88, 27, 137, 151,
#    135, 48, 227, 123, 24, 121, 176, 13, 209, 75, 119, 35, 50, 127, 190, 95, 7,
#    254, 154, 168, 90, 107, 189, 108, 126, 159, 152, 145, 102, 185, 138, 142,
#    ...>>,
#  <<236, 75, 65, 6, 110, 192, 93, 21, 224, 216, 45, 40, 0, 255, 66, 114, 32, 44,
#    225, 73, 14, 105, 237, 27, 19, 105, 161, 18, 103, 244, 49, 181>>}
# pub: "03d44e5bbdc1d413fa6193889a581b89978730e37b1879b00dd14b7723327fbe5f"
# priv: "ec4b41066ec05d15e0d82d2800ff4272202ce1490e69ed1b1369a11267f431b5"



  # defp hex(nil), do: nil
  # defp hex(b) do
  #   Base.encode16(b, case: :lower)
  # end

  defp bin(h) do
    Base.decode16!(h, case: :lower)
  end

  defp pubkey(k), do: k |> bin() |> KeyUtils.decompress()

end
