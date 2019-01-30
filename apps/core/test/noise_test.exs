defmodule Volta.NoiseTest do
  use ExUnit.Case, async: true
  alias Volta.Noise
  alias Volta.KeyUtils

  test "bolt 8 initiator successful handshake" do
    initiator_key = %{
      priv: "1111111111111111111111111111111111111111111111111111111111111111" |> bin(),
      pub:  "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
    }
    e_key = %{
      priv: "1212121212121212121212121212121212121212121212121212121212121212" |> bin(),
      pub:  "036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7" |> pubkey(),
    }
    responder_pk = "028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7" |> bin()
    init_h       = "8401b3fdcaaa710b5405400536a3d5fd7792fe8e7fe29cd8b687216fe323ecbd"
    init_ck      = "2640f52eebcd9e882958951c794250eedb28002c05d7dc2ea0f195406042caf1"
    act1_ss      = "1e2fb3c8fe8fb9f262f649f64d26ecf0f2c0a805a767cf02dc2d77a6ef1fdcc3"
    act1_ck      = "b61ec1191326fa240decc9564369dbb3ae2b34341d1e11ad64ed89f89180582f"
    act1_temp    = "e68f69b7f096d7917245f5e5cf8ae1595febe4d4644333c99f9c4a1282031c9f"
    act1_h       = "9d1ffbb639e7e20021d9259491dc7b160aab270fb1339ef135053f6f2cebe9ce"
    act1_output  = "00036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6a"
    act2_input   = "0002466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730ae" |> bin()
    act2_ss      = "c06363d6cc549bcb7913dbb9ac1c33fc1158680c89e972000ecd06b36c472e47"
    act2_ck      = "e89d31033a1b6bf68c07d22e08ea4d7884646c4b60a9528598ccb4ee2c8f56ba"
    act2_temp    = "908b166535c01a935cf1e130a5fe895ab4e6f3ef8855d87e9b7581c4ab663ddc"
    act2_h       = "90578e247e98674e661013da3c5c1ca6a8c8f48c90b485c0dfa1494e23d56d72"
    act2_re      = "02466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f27"
    act3_h       = "5dcb5ea9b4ccc755e0e3456af3990641276e1d5dc9afd82f974d90a47c918660"
    act3_ss      = "b36b6d195982c5be874d6d542dc268234379e1ae4ff1709402135b7de5cf0766"
    act3_ck      = "919219dbb2920afa8db80f9a51787a840bcf111ed8d588caf9ab4be716e42b01"
    act3_temp    = "981a46c820fb7a241bc8184ba4bb1f01bcdfafb00dde80098cb8c38db9141520"
    act3_sk      = "969ab31b4d288cedf6218839b27a3e2140827047f2c0f01bf5c04435d43511a9"
    act3_rk      = "bb9020b8965f4df047e07f955f3c4b88418984aadc5cdb35096b9ea8fa5c3442"
    act3_output  = "00b9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa22355361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e139ba"
    {:ok, n} = Noise.new(:initiator, responder_pk, initiator_key, [e: e_key])
    assert n[:h]    |> hex() == init_h
    assert n[:ck]   |> hex() == init_ck

    {:ok, n, output} = Noise.act1(n)
    assert n[:ss]   |> hex() == act1_ss
    assert n[:ck]   |> hex() == act1_ck
    assert n[:temp] |> hex() == act1_temp
    assert n[:h]    |> hex() == act1_h
    assert output   |> hex() == act1_output

    {:ok, n        } = Noise.act2(n, act2_input)
    assert n[:ss]   |> hex() == act2_ss
    assert n[:ck]   |> hex() == act2_ck
    assert n[:temp] |> hex() == act2_temp
    assert n[:h]    |> hex() == act2_h
    assert n[:re]   |> hex() == act2_re
    
    {:ok, n, output} = Noise.act3(n)
    assert n[:h]    |> hex() == act3_h
    assert n[:ss]   |> hex() == act3_ss
    assert n[:ck]   |> hex() == act3_ck
    assert n[:temp] |> hex() == act3_temp
    assert n[:sk]   |> hex() == act3_sk
    assert n[:rk]   |> hex() == act3_rk
    assert output   |> hex() == act3_output
    assert n[:rn] == 0
    assert n[:sn] == 0
  end

  defp initiator_act2(act2_input) do
    initiator_key = %{
      priv: "1111111111111111111111111111111111111111111111111111111111111111" |> bin(),
      pub:  "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
    }
    e_key = %{
      priv: "1212121212121212121212121212121212121212121212121212121212121212" |> bin(),
      pub:  "036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7" |> pubkey(),
    }
    responder_pk = "028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7" |> bin()
    act1_output = "00036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6a"
    {:ok, n} = Noise.new(:initiator, responder_pk, initiator_key, [e: e_key])
    {:ok, n, payload} = Noise.act1(n)
    assert payload |> hex() == act1_output

    Noise.act2(n, act2_input)
  end

  test "bolt 8 initiator act2 short read" do
    act2_input = "0002466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730" |> bin()
    {:error, :parsing_error, _msg} = initiator_act2(act2_input)
  end

  test "bolt 8 initiator act2 bad version" do
    act2_input = "0102466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730ae" |> bin()
    {:error, :unsupported_version, _msg} = initiator_act2(act2_input)
  end

  test "bolt 8 initiator act2 bad key serialization" do
    act2_input = "0004466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730ae" |> bin()
    {:error, :bad_pub_key, _msg} = initiator_act2(act2_input)
  end

  test "bolt 8 initiator act2 bad mac" do
    act2_input = "0002466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730af" |> bin()
    {:error, :bad_mac, _msg} = initiator_act2(act2_input)
  end

  test "bolt 8 responder successful handshake" do
    responder_key = %{
      priv: "2121212121212121212121212121212121212121212121212121212121212121" |> bin(),
      pub:  "028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7" |> pubkey(),
    }
    e_key = %{
      priv: "2222222222222222222222222222222222222222222222222222222222222222" |> bin(),
      pub:  "02466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f27" |> pubkey(),
    }
    act1_input   = "00036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6a" |> bin()
    init_h       = "8401b3fdcaaa710b5405400536a3d5fd7792fe8e7fe29cd8b687216fe323ecbd"
    init_ck      = "2640f52eebcd9e882958951c794250eedb28002c05d7dc2ea0f195406042caf1"
    act1_re      = "036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7"
    act1_ss      = "1e2fb3c8fe8fb9f262f649f64d26ecf0f2c0a805a767cf02dc2d77a6ef1fdcc3"
    act1_ck      = "b61ec1191326fa240decc9564369dbb3ae2b34341d1e11ad64ed89f89180582f"
    act1_temp    = "e68f69b7f096d7917245f5e5cf8ae1595febe4d4644333c99f9c4a1282031c9f"
    act1_h       = "9d1ffbb639e7e20021d9259491dc7b160aab270fb1339ef135053f6f2cebe9ce"
    act2_ss      = "c06363d6cc549bcb7913dbb9ac1c33fc1158680c89e972000ecd06b36c472e47"
    act2_ck      = "e89d31033a1b6bf68c07d22e08ea4d7884646c4b60a9528598ccb4ee2c8f56ba"
    act2_temp    = "908b166535c01a935cf1e130a5fe895ab4e6f3ef8855d87e9b7581c4ab663ddc"
    act2_h       = "90578e247e98674e661013da3c5c1ca6a8c8f48c90b485c0dfa1494e23d56d72"
    act2_output  = "0002466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730ae"
    act3_input   = "00b9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa22355361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e139ba" |> bin()
    #act3_rs      = "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa"
    act3_h       = "5dcb5ea9b4ccc755e0e3456af3990641276e1d5dc9afd82f974d90a47c918660"
    act3_ss      = "b36b6d195982c5be874d6d542dc268234379e1ae4ff1709402135b7de5cf0766"
    act3_ck      = "919219dbb2920afa8db80f9a51787a840bcf111ed8d588caf9ab4be716e42b01"
    act3_temp    = "981a46c820fb7a241bc8184ba4bb1f01bcdfafb00dde80098cb8c38db9141520"
    act3_rk      = "969ab31b4d288cedf6218839b27a3e2140827047f2c0f01bf5c04435d43511a9"
    act3_sk      = "bb9020b8965f4df047e07f955f3c4b88418984aadc5cdb35096b9ea8fa5c3442"

    {:ok, n} = Noise.new(:responder, responder_key, [e: e_key])
    assert n[:h]       |> hex() == init_h
    assert n[:ck]      |> hex() == init_ck

    {:ok, n} = Noise.act1(n, act1_input)
    assert n[:re]   |> hex() == act1_re
    assert n[:ss]   |> hex() == act1_ss
    assert n[:ck]   |> hex() == act1_ck
    assert n[:temp] |> hex() == act1_temp
    assert n[:h]    |> hex() == act1_h

    {:ok, n, output} = Noise.act2(n)
    assert n[:ss]   |> hex() == act2_ss
    assert n[:ck]   |> hex() == act2_ck
    assert n[:temp] |> hex() == act2_temp
    assert n[:h]    |> hex() == act2_h
    assert output   |> hex() == act2_output
    
    {:ok, n} = Noise.act3(n, act3_input)
    assert n[:h]    |> hex() == act3_h
    assert n[:ss]   |> hex() == act3_ss
    assert n[:ck]   |> hex() == act3_ck
    assert n[:temp] |> hex() == act3_temp
    assert n[:sk]   |> hex() == act3_sk
    assert n[:rk]   |> hex() == act3_rk
    assert n[:rn] == 0
    assert n[:sn] == 0
  end

  defp responder_act1(act1_input) do
    responder_key = %{
      priv: "2121212121212121212121212121212121212121212121212121212121212121" |> bin(),
      pub:  "028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7" |> pubkey(),
    }
    e_key = %{
      priv: "2222222222222222222222222222222222222222222222222222222222222222" |> bin(),
      pub:  "02466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f27" |> pubkey(),
    }
    #act1_output = "00036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6a"
    {:ok, n} = Noise.new(:responder, responder_key, [e: e_key])
    Noise.act1(n, act1_input)
  end

  test "bolt 8 responder act1 short read" do
    act1_input = "00036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c" |> bin()
    {:error, :parsing_error, _msg} = responder_act1(act1_input)
  end

  test "bolt 8 responder act1 bad version" do
    act1_input = "01036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6a" |> bin()
    {:error, :unsupported_version, _msg} = responder_act1(act1_input)
  end

  test "bolt 8 responder act1 bad key serialization" do
    act1_input = "00046360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6a" |> bin()
    {:error, :bad_pub_key, _msg} = responder_act1(act1_input)
  end

  test "bolt 8 responder act1 bad MAC" do
    act1_input = "00036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6b" |> bin()
    {:error, :bad_mac, _msg} = responder_act1(act1_input)
  end

  defp responder_act3(act3_input) do
    act1_input = "00036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6a" |> bin()
    act2_output = "0002466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730ae"
    {:ok, n} = responder_act1(act1_input)
    {:ok, n, output} = Noise.act2(n)
    assert output |> hex() == act2_output
    Noise.act3(n, act3_input)
  end

  test "bolt 8 responder bad version" do
    act3_input = "01b9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa22355361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e139ba" |> bin()
    {:error, :unsupported_version, _msg} = responder_act3(act3_input)
  end

  test "bolt 8 responder short read" do
    act3_input = "00b9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa22355361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e139" |> bin()
    {:error, :parsing_error, _msg} = responder_act3(act3_input)
  end

  test "bolt 8 responder bad MAC for ciphertext" do
    act3_input = "00c9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa22355361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e139ba" |> bin()
    {:error, :bad_mac, _msg} = responder_act3(act3_input)
  end

  test "bolt 8 responder bad rs" do
    act3_input = "00bfe3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa2235536ad09a8ee351870c2bb7f78b754a26c6cef79a98d25139c856d7efd252c2ae73c" |> bin()
    {:error, :bad_pub_key, _msg} = responder_act3(act3_input)
  end

  test "bolt 8 responder bad MAC" do
    act3_input = "00b9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa22355361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e139bb" |> bin()
    {:error, :bad_mac, _msg} = responder_act3(act3_input)
  end

  test "bolt 8 message encryption" do
    initiator_key = %{
      priv: "1111111111111111111111111111111111111111111111111111111111111111" |> bin(),
      pub:  "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
    }
    initiator_e_key = %{
      priv: "1212121212121212121212121212121212121212121212121212121212121212" |> bin(),
      pub:  "036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7" |> pubkey(),
    }
    responder_key = %{
      priv: "2121212121212121212121212121212121212121212121212121212121212121" |> bin(),
      pub:  "028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7" |> pubkey(),
    }
    responder_e_key = %{
      priv: "2222222222222222222222222222222222222222222222222222222222222222" |> bin(),
      pub:  "02466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f27" |> pubkey(),
    }
    {:ok, n1} = Noise.new(:initiator, responder_key[:pub], initiator_key, [e: initiator_e_key])
    {:ok, n2} = Noise.new(:responder, responder_key, [e: responder_e_key])
    {:ok, n1, output} = Noise.act1(n1)
    {:ok, n2        } = Noise.act1(n2, output)
    {:ok, n2, output} = Noise.act2(n2)
    {:ok, n1        } = Noise.act2(n1, output)
    {:ok, n1, output} = Noise.act3(n1)
    {:ok, n2        } = Noise.act3(n2, output)

    ck = "919219dbb2920afa8db80f9a51787a840bcf111ed8d588caf9ab4be716e42b01"
    sk = "969ab31b4d288cedf6218839b27a3e2140827047f2c0f01bf5c04435d43511a9"
    rk = "bb9020b8965f4df047e07f955f3c4b88418984aadc5cdb35096b9ea8fa5c3442"
    assert n1[:ck] |> hex() == ck
    assert n1[:sk] |> hex() == sk
    assert n1[:rk] |> hex() == rk

    {_n1, results} =
    Enum.to_list(0..1001)
    |> Enum.reduce({n1, %{}}, fn i, {n, r} -> 
      {:ok, n, ciphertext} = Noise.encrypt(n, "hello")
      {n, Map.put(r, i, ciphertext)}
    end)

    assert results[0]    |> hex() == "cf2b30ddf0cf3f80e7c35a6e6730b59fe802473180f396d88a8fb0db8cbcf25d2f214cf9ea1d95"
    assert results[1]    |> hex() == "72887022101f0b6753e0c7de21657d35a4cb2a1f5cde2650528bbc8f837d0f0d7ad833b1a256a1"
    assert results[500]  |> hex() == "178cb9d7387190fa34db9c2d50027d21793c9bc2d40b1e14dcf30ebeeeb220f48364f7a4c68bf8"
    assert results[501]  |> hex() == "1b186c57d44eb6de4c057c49940d79bb838a145cb528d6e8fd26dbe50a60ca2c104b56b60e45bd"
    assert results[1000] |> hex() == "4a2f3cc3b5e78ddb83dcb426d9863d9d9a723b0337c89dd0b005d89f8d3c05c52b76b29b740f09"
    assert results[1001] |> hex() == "2ecd8c8a5629d0d02ab457a0fdd0f7b90a192cd46be5ecb6ca570bfc5e268338b1a16cf4ef2d36"

    {_n2, plaintext_results} = 
    Enum.to_list(0..1001)
    |> Enum.reduce({n2, %{}}, fn i, {n, r} ->
      <<le::bytes-size(18), c::binary>> = results[i]
      {:ok, n, _length} = Noise.decrypt_length(n, le)
      {:ok, n, plaintext} = Noise.decrypt_message(n, c)
      {n, Map.put(r, i, plaintext)}
    end)

    assert plaintext_results[0] == "hello"
    assert plaintext_results[1] == "hello"
    assert plaintext_results[500] == "hello"
    assert plaintext_results[501] == "hello"
    assert plaintext_results[1000] == "hello"
    assert plaintext_results[1001] == "hello"
  end

  test "encrypt decrypt msg" do
    initiator_key = %{
      priv: "1111111111111111111111111111111111111111111111111111111111111111" |> bin(),
      pub:  "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
    }
    responder_key = %{
      priv: "2121212121212121212121212121212121212121212121212121212121212121" |> bin(),
      pub:  "028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7" |> pubkey(),
    }
    {:ok, n1} = Noise.new(:initiator, responder_key[:pub], initiator_key, [])
    {:ok, n2} = Noise.new(:responder, responder_key, [])
    {:ok, n1, output} = Noise.act1(n1)
    {:ok, n2        } = Noise.act1(n2, output)
    {:ok, n2, output} = Noise.act2(n2)
    {:ok, n1        } = Noise.act2(n1, output)
    {:ok, n1, output} = Noise.act3(n1)
    {:ok, n2        } = Noise.act3(n2, output)

    {:ok, _n1, encrypted_payload} = Noise.encrypt(n1, "hello")
    <<le::bytes-size(18), ciphertext::binary>> = encrypted_payload

    {:ok, n2, length} = Noise.decrypt_length(n2, le)
    assert length == 21
    
    {:ok, _n2, decrypted} = Noise.decrypt_message(n2, ciphertext)
    assert decrypted == "hello"
  end

  test "do not encrypt messages that are too big" do
    #TODO
  end

  test "error on receiving message length that is too big" do
    #TODO
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
