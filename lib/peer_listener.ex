defmodule Lnx.PeerListener do
  alias Lnx.PeerConn

  def start(opts) do
    random_hex = Base.encode16(<<:rand.uniform(4_000_000_000)::unsigned-size(32)>>, case: :lower)
    port = Keyword.get(opts, :port, 2345)
    name = Keyword.get(opts, :name, String.to_atom("peer_listener_#{random_hex}"))
    max_connections = Keyword.get(opts, :max_connections, 2000)
    protocol_opts = Keyword.get(opts, :protocol_opts, [])

    case :ranch.start_listener(
           name,
           :ranch_tcp,
           %{max_connections: max_connections, socket_opts: [port: port]},
           PeerConn,
           protocol_opts
         ) do
      {:ok, pid} -> {:ok, pid, name}
    end
  end

  def stop(listener) do
    case :ranch.stop_listener(listener) do
      :ok -> :ok
    end
  end
end
