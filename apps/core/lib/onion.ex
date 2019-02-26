defmodule Volta.Core.Onion do
  alias Volta.KeyUtils

  defmodule OnionPacketV0 do
    alias Volta.Core.Onion.PerHop
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

    def encode(packet) do
      <<
        packet.version::unsigned-big-size(8),
      >> 
      <> packet.public_key
      <> packet.hops_data
      <> packet.hmac
    end

    def decode(<<
      version::unsigned-big-size(8),
      public_key::bytes-size(33),
      hops_data::bytes-size(1300),
      hmac::bytes-size(32),
      >>) do
      %OnionPacketV0{
        version: version,
        public_key: public_key,
        hops_data: hops_data,
        hmac: hmac,
      }
    end

    def create(payment_path, session_key, associated_data) do
      [packet | _] = create_with_intermediates(payment_path, session_key, associated_data)
      packet
    end

    # def unwrap(packet, key) do
    #   shared_secret = generate_shared_secret()
    #   rho_key = generate_key("rho", shared_secret)
    #   stream_bytes = generate_cipher_stream(rho_key, @num_stream_bytes)
    #   padding_bits = @hop_data_size * 8
    #   header_with_padding = packet.hops_data <> <<0::size(padding_bits)>>
    #   decrypted = :crypto.exor(header_with_padding, stream_bytes)

    #   {:ok, ecdh_result} = :libsecp256k1.ec_pubkey_tweak_mul(key[:pub], ephem_key)
    #   hop_shared_secret = :crypto.hash(:sha256, KeyUtils.compress(ecdh_result))

    #   blinding_factor = :crypto.hash(:sha256, KeyUtils.compress(ephem_pub_key) <> hop_shared_secret)

    # end

    # defp generate_shared_secret() do
      
    # end

    def create_with_intermediates(payment_path, session_key, associated_data) do

      {reverse_hop_shared_secrets, ephem_key, blinding_factors, ephem_keys} = 
      payment_path
      |> Enum.map(fn {pub_key, _payload} -> pub_key end)
      |> Enum.reduce({[], session_key, [], []}, fn hop_pub_key, {hop_shared_secrets, ephem_key, bfs, eks} ->
        {:ok, ecdh_result} = :libsecp256k1.ec_pubkey_tweak_mul(hop_pub_key, ephem_key)
        hop_shared_secret = :crypto.hash(:sha256, KeyUtils.compress(ecdh_result))

        ephem_pub_key = KeyUtils.pub_from_priv(ephem_key)
        blinding_factor = :crypto.hash(:sha256, KeyUtils.compress(ephem_pub_key) <> hop_shared_secret)
        {:ok, ephem_key} = :libsecp256k1.ec_privkey_tweak_mul(ephem_key, blinding_factor)
        
        {
          [hop_shared_secret | hop_shared_secrets], 
          ephem_key,
          [blinding_factor | bfs],
          [ephem_pub_key | eks],
        }
      end)

      hop_shared_secrets = Enum.reverse(reverse_hop_shared_secrets) |> Enum.to_list()

      num_hops = length(payment_path)
      filler = generate_filler(
        "rho", 
        num_hops, 
        @hop_data_size, 
        hop_shared_secrets
      )

      empty_header_bits = @routing_info_size * 8
      empty_mix_header = <<0::size(empty_header_bits)>>
      empty_hmac = <<0::size(256)>>

      {last_hmac, mix_header, _, rho_keys, mu_keys, plain_routing_infos, encrypted_routing_infos, hmac_datas, hmacs} = 
      Enum.zip(Enum.reverse(payment_path), reverse_hop_shared_secrets)
      |> Enum.with_index()
      |> Enum.map(fn {{{a, b}, c}, i} -> {i, a, b, c} end)
      |> Enum.reduce(
        {empty_hmac, empty_mix_header, empty_hmac, [], [], [], [], [], []}, 
        fn {i, hop_pub_key, hop_payload, shared_secret}, {last_hmac, mix_header, hmac, rho_keys, mu_keys, pri, eri, hmac_datas, hmacs} -> 
          
        rho_key = generate_key("rho", shared_secret)
        mu_key = generate_key("mu", shared_secret)

        hop_data = <<0>> <> PerHop.encode(hop_payload) <> hmac
        mix_header = hop_data <> binary_part(mix_header, 0, @routing_info_size - @hop_data_size)
        plain_routing_info = mix_header

        stream_bytes = generate_cipher_stream(rho_key, @routing_info_size)
        mix_header = :crypto.exor(mix_header, stream_bytes) 

        mix_header = 
        if i == 0 do
          mix_length = byte_size(mix_header) - byte_size(filler)
          binary_part(mix_header, 0, mix_length) <> filler
        else
          mix_header
        end
        encrypted_routing_info = mix_header

        packet = mix_header <> associated_data
        next_hmac = calc_mac(mu_key, packet)

        {
          next_hmac, 
          mix_header, 
          next_hmac, 
          [rho_key | rho_keys], 
          [mu_key | mu_keys],
          [plain_routing_info | pri],
          [encrypted_routing_info | eri],
          [packet | hmac_datas],
          [next_hmac | hmacs],
        }
      end)

      packet = %OnionPacketV0{
        version: 0,
        public_key: KeyUtils.pub_from_priv(session_key) |> KeyUtils.compress(),
        hops_data: mix_header,
        hmac: last_hmac,
      }

      [
        packet,
        hop_shared_secrets,
        blinding_factors |> Enum.reverse() |> Enum.to_list(),
        ephem_keys |> Enum.reverse() |> Enum.to_list(),
        filler,
        rho_keys,
        mu_keys,
        plain_routing_infos,
        encrypted_routing_infos,
        hmac_datas,
        hmacs,
      ]

    end

    defp generate_filler(key, num_hops, hop_size, shared_secrets) do
      filler_size = @num_max_hops * hop_size
      filler_size_bits = filler_size * 8
      empty_filler = <<0::size(filler_size_bits)>>
      pad_size_bits = hop_size * 8
      pad = <<0::size(pad_size_bits)>>

      filler_start = (@num_max_hops - num_hops + 1) * hop_size
      filler_final_size = filler_size - filler_start
      
      shared_secrets
      |> Enum.take(num_hops - 1)
      |> Enum.reduce(empty_filler, fn(shared_secret, filler) -> 
        stream_key = generate_key(key, shared_secret)
        stream_bytes = generate_cipher_stream(stream_key, filler_size + hop_size)
        :crypto.exor(filler <> pad, stream_bytes) 
        |> binary_part(hop_size, filler_size)
      end)
      |> binary_part(filler_start, filler_final_size)
    end

    defp generate_key(key, shared_secret) do
      :libsecp256k1.hmac_sha256(key, shared_secret)
    end

    defp generate_cipher_stream(key, size) do
      nonce = <<0::size(64)>>
      :enacl.stream_chacha20(size, nonce, key)
    end

    defp calc_mac(key, msg) do
      :libsecp256k1.hmac_sha256(key, msg)
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
