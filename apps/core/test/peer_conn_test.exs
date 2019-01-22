defmodule Volta.PeerConnTest do
  use ExUnit.Case, async: true
  alias Volta.PeerConn
  alias Volta.PeerListener
  alias Volta.KeyUtils
  alias Volta.LightningMsg
  alias Volta.Testing.LND
  alias Volta.Testing.Bitcoind

  test "connect and send message" do
    initiator_key = %{
      priv: "1111111111111111111111111111111111111111111111111111111111111111" |> bin(),
      pub:  "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
    }
    responder_key = %{
      priv: "2121212121212121212121212121212121212121212121212121212121212121" |> bin(),
      pub:  "028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7" |> pubkey(),
    }

    {:ok, _pid, peer_listener_name} = PeerListener.start([
      port: 2345, 
      protocol_opts: [key: responder_key, subscribers: [self()]]])
    
    {:ok, client} = PeerConn.start_link([
      ip: "127.0.0.1", 
      port: 2345, 
      key: initiator_key, 
      remote_key: responder_key[:pub]])

    ping_msg = %LightningMsg.PingMsg{ping_bytes: 1, pong_bytes: 2}
    :ok = PeerConn.send(client, ping_msg)
    assert_receive ^ping_msg

    :ok = PeerConn.stop(client)
    :ok = PeerListener.stop(peer_listener_name)
  end

  @tag :slow
  test "connect to lnd and exchange init & ping/pong" do
    {:ok, bitcoind} = Bitcoind.start_link()
    :ok = Bitcoind.mine_blocks(bitcoind, count: 1)
    {:ok, lnd} = LND.start_link([bitcoind: [pid: bitcoind]])
    :ok = LND.wait_for_ready(lnd)
        
    client_key = %{
      priv: "1111111111111111111111111111111111111111111111111111111111111111" |> bin(),
      pub:  "034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa" |> pubkey(),
    }
    pubkey = LND.state(lnd)[:identity_pubkey]

    {:ok, client} = PeerConn.connect([
      ip: "127.0.0.1",
      port: LND.state(lnd)[:peer_port],
      key: client_key,
      remote_key: pubkey,
      subscribers: [self()],
    ])

    :ok = PeerConn.send(client, %LightningMsg.InitMsg{})
    expected_init = %LightningMsg.InitMsg{global_features: <<>>, local_features: <<130>>}
    assert_receive ^expected_init, 5000

    :ok = PeerConn.send(client, %LightningMsg.PingMsg{ping_bytes: 8, pong_bytes: 8})
    expected_pong = %LightningMsg.PongMsg{pong_bytes: 8}
    assert_receive ^expected_pong, 5000


    PeerConn.stop(client)
    LND.stop(lnd)
    Bitcoind.stop(bitcoind)
  end

  defp bin(h) do
    Base.decode16!(h, case: :lower)
  end

  defp pubkey(k), do: k |> bin() |> KeyUtils.decompress()

end
