defmodule Volta.Core.Onion do
  alias Volta.KeyUtils

  defmodule OnionPacketV0 do
    @num_max_hops 20
    @hop_data_size 65
    @routing_info_size (@num_max_hops * @hop_data_size)
    @num_stream_bytes (@routing_info_size + @hop_data_size)

    defstruct [
      :version,
      :public_key,
      :hops_data,
      :hmac,
    ]

    def create(payment_path, session_key, associated_data) do

      {reverse_hop_shared_secrets, ephem_key} = 
      payment_path
      |> Enum.map(fn {pub_key, _payload} -> pub_key end)
      |> Enum.reduce({[], session_key}, fn hop_pub_key, {hop_shared_secrets, ephem_key} ->
        {:ok, ecdh_result} = :libsecp256k1.ec_pubkey_tweak_mul(hop_pub_key, ephem_key)
        hop_shared_secret = :crypto.hash(:sha256, KeyUtils.compress(ecdh_result))

        ephem_pub_key = KeyUtils.pub_from_priv(ephem_key)
        blinding_factor = :crypto.hash(:sha256, KeyUtils.compress(ephem_pub_key) <> hop_shared_secret)
        {:ok, ephem_key} = :libsecp256k1.ec_privkey_tweak_mul(ephem_key, blinding_factor)

        {[hop_shared_secret | hop_shared_secrets], ephem_key}
      end)

      hop_shared_secrets = Enum.reverse(reverse_hop_shared_secrets) |> Enum.to_list()

      filler = generate_filler(
        "rho", 
        length(payment_path), 
        @hop_data_size, 
        hop_shared_secrets
      )

      empty_header_bits = @routing_info_size * 8
      empty_mix_header = <<0::size(empty_header_bits)>>
      empty_hmac = <<0::size(256)>>

      {hmacs, mix_header, _} = 
      Enum.zip(payment_path, hop_shared_secrets)
      |> Enum.reverse()
      |> Enum.map(fn {{a, b}, c} -> {a, b, c} end)
      |> Enum.reduce({[], empty_mix_header, empty_hmac}, fn {hop_pub_key, hop_payload, shared_secret}, {hmacs, mix_header, hmac} -> 
        rho_key = generate_key("rho", shared_secret)
        mu_key = generate_key("mu", shared_secret)

        stream_bytes = generate_cipher_stream(rho_key, @num_stream_bytes) |> binary_part(0, @routing_info_size)
        mix_header = hop_payload <> binary_part(mix_header, @hop_data_size, @routing_info_size - @hop_data_size)
        mix_header = :crypto.exor(mix_header, stream_bytes) 

        packet = mix_header <> associated_data
        next_hmac = calc_mac(mu_key, packet)

        {[hmac | hmacs], mix_header, next_hmac}
      end)

      %OnionPacketV0{
        version: 0,
        public_key: KeyUtils.pub_from_priv(session_key),
        hops_data: mix_header,
        hmac: List.last(hmacs),
      }

    end

    defp generate_filler(key, num_hops, hop_size, shared_secrets) do
      filler_size = @num_max_hops * hop_size
      filler_size_bits = filler_size * 8
      empty_filler = <<0::size(filler_size_bits)>>
      pad_size_bits = hop_size * 8
      pad = <<0::size(pad_size_bits)>>
      
      shared_secrets
      |> Enum.take(num_hops - 1)
      |> Enum.reduce(empty_filler, fn(shared_secret, filler) -> 
        stream_key = generate_key(key, shared_secret)
        stream_bytes = generate_cipher_stream(stream_key, filler_size + hop_size)
        :crypto.exor(filler <> pad, stream_bytes) 
        |> binary_part(hop_size, filler_size)
      end)
    end

    defp generate_key(key, shared_secret) do
      :libsecp256k1.hmac_sha256(key, shared_secret)
    end

    defp generate_cipher_stream(key, size) do
      # TODO: Constant nonce is ok because each key is used once?
      nonce = <<0::size(64)>>
      :enacl.stream_chacha20(size, nonce, key)
    end

    defp calc_mac(key, data) do
      
    end

  end

  def parse_packet(<<version, rest::binary>>) do
    parse_packet(version, rest)
  end

  def parse_packet(
        0,
        <<public_key::bytes-size(33),
          hops_data::bytes-size(1300),
          hmac::bytes-size(32)>>) do

  end

  defmodule HopData do
    defstruct [
      :realm,
      :per_hop,
      :hmac,
    ]
  end

  defmodule PerHop do
    defstruct [
      :short_channel_id,
      :amt_to_forward,
      :outgoing_cltv_value,
    ]

    def parse(0, <<
      short_channel_id::unsigned-big-size(64),
      amt_to_forward::unsigned-big-size(64),
      outgoing_cltv_value::unsigned-big-size(32),
      _padding::bytes-size(12),
      >>) do
      %PerHop{
        short_channel_id: short_channel_id,
        amt_to_forward: amt_to_forward,
        outgoing_cltv_value: outgoing_cltv_value,
      }
    end

    def encode(%PerHop{} = per_hop) do
      <<
        per_hop.short_channel_id::unsigned-big-size(64),
        per_hop.amt_to_forward::unsigned-big-size(64),
        per_hop.outgoing_cltv_value::unsigned-big-size(32),
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
      >>
    end
  end


end
