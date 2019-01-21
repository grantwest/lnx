#https://github.com/lightningnetwork/lightning-rfc/blob/1fd1e76f9e898b423249316b9dec62dd0bacbb2a/08-transport.md

defmodule Volta.Noise do
  alias Volta.KeyUtils
  alias Volta.NoiseError
  @protocol_name "Noise_XK_secp256k1_ChaChaPoly_SHA256"
  @prologue "lightning"

  def new(role, remote_pub_key, local_key, opts \\ []) do
    ck = :crypto.hash(:sha256, @protocol_name)
    h = :crypto.hash(:sha256, ck <> @prologue)
    h = case role do
      :initiator -> sha256(h, KeyUtils.compress(remote_pub_key))
      :responder -> sha256(h, KeyUtils.compress(local_key[:pub]))
    end
    {:ok, initial_state(opts)
        |> Map.put(:role, role)
        |> Map.put(:h, h)
        |> Map.put(:ck, ck)
        |> Map.put(:remote_pub_key, KeyUtils.decompress(remote_pub_key))
        |> Map.put(:local_key, local_key) 
    }
  end

  defp initial_state([]), do: %{}
  defp initial_state([e: e]), do: %{e: e}

  defp sha256(h, other) do
    :crypto.hash(:sha256, h <> other)
  end

  defp ecdh(rk, k) do
    {:ok, pub} = :libsecp256k1.ec_pubkey_tweak_mul(rk, k)
    :crypto.hash(:sha256, KeyUtils.compress(pub))
  end

  defp hkdf(salt, ikm) do
    <<ck::bytes-size(32), temp::bytes-size(32)>> = HKDF.derive(:sha256, ikm, 64, salt)
    {ck, temp}
  end

  defp encrypt_with_ad(k, n, ad, plaintext) do
    :enacl.aead_chacha20poly1305_encrypt(k, n, ad, plaintext)
  end

  defp decrypt_with_ad(k, n, ad, ciphertext) do
    case :enacl.aead_chacha20poly1305_decrypt(k, n, ad, ciphertext) do
      {:error, :aead_chacha20poly1305_ietf_decrypt_failed} ->
        raise(NoiseError, type: :bad_mac, message: "Bad MAC")
      p -> p
    end
  end

  def handle_errors(code) do
    try do
      code.()
    rescue
      e in NoiseError -> {:error, e.type, e.message}
    end
  end

  def act1(%{role: :initiator, h: h, ck: ck, remote_pub_key: rpk} = state) do
    e = generate_e(state)
    h = sha256(h, KeyUtils.compress(e[:pub]))
    ss = ecdh(rpk, e[:priv])
    {ck, temp_k1} = hkdf(ck, ss)
    c = encrypt_with_ad(temp_k1, 0, h, <<>>)
    h = sha256(h, c)
    payload = <<0>> <> KeyUtils.compress(e[:pub]) <> c

    {:ok, state
        |> Map.put(:e, e)
        |> Map.put(:h, h)
        |> Map.put(:ss, ss)
        |> Map.put(:ck, ck)
        |> Map.put(:temp, temp_k1),
      payload
    }
  end

  def act1(%{role: :responder, h: h, ck: ck, local_key: s} = state, input) do
    handle_errors(fn -> 
      {_v, re, c} = parse(input)
      h = sha256(h, KeyUtils.compress(re))
      ss = ecdh(re, s[:priv])
      {ck, temp_k1} = hkdf(ck, ss)
      _p = decrypt_with_ad(temp_k1, 0, h, c)
      h = sha256(h, c)

      {:ok, state
          |> Map.put(:re, re)
          |> Map.put(:ss, ss)
          |> Map.put(:ck, ck)
          |> Map.put(:temp, temp_k1)
          |> Map.put(:h, h)
      }
    end)
  end

  def act2(%{role: :initiator, h: h, ck: ck, e: e} = state, input) do
    handle_errors(fn -> 
      {_v, re, c} = parse(input)
      h = sha256(h, re)
      ss = ecdh(re, e[:priv])
      {ck, temp_k2} = hkdf(ck, ss)
      decrypt_with_ad(temp_k2, 0, h, c) 
      h = sha256(h, c)

      {:ok, state
          |> Map.put(:h, h)
          |> Map.put(:ss, ss)
          |> Map.put(:ck, ck)
          |> Map.put(:temp, temp_k2)
          |> Map.put(:re, re)
      }
    end)
  end

  def act2(%{role: :responder, h: h, ck: ck, re: re} = state) do
    e = generate_e(state)
    h = sha256(h, KeyUtils.compress(e[:pub]))
    ss = ecdh(re, e[:priv])
    {ck, temp_k2} = hkdf(ck, ss)
    c = encrypt_with_ad(temp_k2, 0, h, <<>>)
    h = sha256(h, c)
    payload = <<0>> <> KeyUtils.compress(e[:pub]) <> c

    {:ok, state
        |> Map.put(:e, e)
        |> Map.put(:ss, ss)
        |> Map.put(:ck, ck)
        |> Map.put(:temp, temp_k2)
        |> Map.put(:h, h),
      payload
    }
  end

  def act3(%{role: :initiator, h: h, ck: ck, re: re, local_key: s, temp: temp_k2} = state) do
    c = encrypt_with_ad(temp_k2, 1, h, KeyUtils.compress(s[:pub]))
    h = sha256(h, c)
    ss = ecdh(re, s[:priv])
    {ck, temp_k3} = hkdf(ck, ss)
    t = encrypt_with_ad(temp_k3, 0, h, <<>>)
    {sk, rk} = hkdf(ck, <<>>)
    payload = <<0>> <> c <> t

    {:ok, state
        |> Map.put(:h, h)
        |> Map.put(:ss, ss)
        |> Map.put(:ck, ck)
        |> Map.put(:temp, temp_k3)
        |> Map.put(:sk, sk)
        |> Map.put(:rk, rk)
        |> Map.put(:rn, 0)
        |> Map.put(:sn, 0),
      payload
    }
  end

  def act3(%{role: :responder, h: h, ck: ck, temp: temp_k2, e: e} = state, input) do
    handle_errors(fn -> 
      {_v, c, t} = parse(input)
      rs = decrypt_with_ad(temp_k2, 1, h, c)
      check_public_key(rs)
      h = sha256(h, c)
      ss = ecdh(rs, e[:priv])
      {ck, temp_k3} = hkdf(ck, ss)
      _p = decrypt_with_ad(temp_k3, 0, h, t)
      {rk, sk} = hkdf(ck, <<>>)

      {:ok, state
          |> Map.put(:h, h)
          |> Map.put(:ss, ss)
          |> Map.put(:ck, ck)
          |> Map.put(:temp, temp_k3)
          |> Map.put(:sk, sk)
          |> Map.put(:rk, rk)
          |> Map.put(:rn, 0)
          |> Map.put(:sn, 0)
      }
    end)
  end

  defp maybe_rotate_send_key(state) do
    if state[:sn] >= 1000 do
      {ck, sk} = hkdf(state[:ck], state[:sk])
      %{state | ck: ck, sk: sk, sn: 0}  
    else
      state
    end
  end

  defp maybe_rotate_recv_key(state) do
    if state[:rn] >= 1000 do
      {ck, rk} = hkdf(state[:ck], state[:rk])
      %{state | ck: ck, rk: rk, rn: 0}  
    else
      state
    end
  end

  defp encrypt_item(%{sk: sk, sn: sn} = state, plaintext) do
    {ciphertext, mac} = :crypto.block_encrypt(
      :chacha20_poly1305, 
      sk, 
      <<0, 0, 0, 0, sn::unsigned-little-size(64)>>, 
      {<<>>, plaintext}
    )
    state = Map.put(state, :sn, sn + 1)
    state = maybe_rotate_send_key(state)
    {state, ciphertext <> mac}
  end

  def encrypt(state, plaintext) do
    l = byte_size(plaintext)
    {state, le} = encrypt_item(state, <<l::unsigned-big-size(16)>>)
    {state, c}  = encrypt_item(state, plaintext)
    payload = le <> c

    {:ok, state, payload}
  end

  defp decrypt_item(%{rk: rk, rn: rn} = state, encrypted_payload) do
    msg_length = byte_size(encrypted_payload) - 16
    <<ciphertext::bytes-size(msg_length), mac::bytes-size(16)>> = encrypted_payload
    plaintext = :crypto.block_decrypt(
      :chacha20_poly1305, 
      rk, 
      <<0, 0, 0, 0, rn::unsigned-little-size(64)>>, 
      {<<>>, ciphertext, mac}
    )
    state = Map.put(state, :rn, rn + 1)
    state = maybe_rotate_recv_key(state)
    {state, plaintext}
  end

  def decrypt_length(state, encrypted_payload) do
    {state, <<l::unsigned-big-size(16)>>} = decrypt_item(state, encrypted_payload)
    {:ok, state, l + 16}
  end

  def decrypt_message(state, encrypted_payload) do
    {state, plaintext} = decrypt_item(state, encrypted_payload)
    {:ok, state, plaintext}
  end

  defp generate_e(%{e: e}), do: e
  defp generate_e(_) do
    {pub, priv} = :crypto.generate_key(:ecdh, :secp256k1)
    %{pub: pub, priv: priv}
  end

  defp parse(<<version, remote_ephem::bytes-size(33), c::bytes-size(16)>>) do
    check_version(version)
    check_public_key(remote_ephem)
    {version, remote_ephem, c}
  end

  defp parse(<<version, c::bytes-size(49), t::bytes-size(16)>>) do
    check_version(version)
    {version, c, t}
  end

  defp parse(input), do: raise(NoiseError, type: :parsing_error, message: "incorrect number of bytes, expected 50 or 66, got #{byte_size(input)}")

  defp check_version(0), do: true
  defp check_version(v), do: raise(NoiseError, type: :unsupported_version, message: "expected version 0, but got #{v}")

  defp check_public_key(key) do
    unless KeyUtils.valid_public_key?(key) do
      raise(NoiseError, type: :bad_pub_key, message: "Bad public key: #{hex(key)}")
    end
  end

  defp hex(b) do
    Base.encode16(b, case: :lower)
  end

end

defmodule Volta.NoiseError do
  defexception [:type, :message]
end
