defmodule Volta.PeerConn do
  use GenServer
  alias Volta.Noise
  alias Volta.LightningMsg
  @behaviour :ranch_protocol

  def start_link(ref, socket, transport, opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
    {:ok, pid}
  end

  def init(ref, socket, transport, opts) do
    :ok = :ranch.accept_ack(ref) # or maybe :ranch.handshake(ref)
    :ok = transport.setopts(socket, [{:active, false}])
    Kernel.send(self(), :handshake)
    :gen_server.enter_loop(__MODULE__, [], %{
      socket: socket, 
      transport: transport, 
      key: Keyword.get(opts, :key),
      subscribers: Keyword.get(opts, :subscribers, []),
      role: :responder, 
      handshake: :incomplete,
    })
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def init(opts) do
    ip = Keyword.get(opts, :ip)
    port = Keyword.get(opts, :port)
    socket_opts = [active: false, mode: :binary]
    {:ok, socket} = :gen_tcp.connect(to_charlist(ip), port, socket_opts, 1000)
    Kernel.send(self(), :handshake)
    state = %{
      socket: socket,
      key: Keyword.get(opts, :key),
      remote_key: Keyword.get(opts, :remote_key),
      subscribers: Keyword.get(opts, :subscribers, []),
      role: :initiator,
      handshake: :incomplete,
    }
    {:ok, state}
  end

  def connect(opts) do
    start_link(opts)
  end
  
  def send(conn, msg) do
    GenServer.call(conn, {:send, LightningMsg.encode(msg)})
  end

  def stop(conn) do
    :ok = GenServer.stop(conn, :normal)
    :ok
  end

  def handle_call({:send, msg}, _from, %{handshake: :done, noise: n} = state) do
    {:ok, n, encryped_msg} = Noise.encrypt(n, msg)
    :ok = :gen_tcp.send(state[:socket], encryped_msg)
    {:reply, :ok, %{state | noise: n}}
  end

  def handle_info({:tcp, _socket, msg}, %{noise: n} = state) do
    active_once(state)
    {:ok, n, decrypted_msg} = Noise.decrypt(n, msg)
    parsed_msg = LightningMsg.parse(decrypted_msg)
    for s <- state[:subscribers], do: Kernel.send(s, parsed_msg)
    {:noreply, %{state | noise: n}}
  end

  def handle_info(:handshake, state) do
    case handshake(state) do
      {:ok, state} -> 
        active_once(state)
        {:noreply, state}
      {:error, type, reason} -> {:stop, {:error, type, reason}}
    end
  end

  defp handshake(%{role: :initiator, socket: socket} = state) do
    {:ok, n} = Noise.new(:initiator, state[:remote_key], state[:key], [])
    {:ok, n, output} = Noise.act1(n)
    :ok = :gen_tcp.send(socket, output)
    {:ok, act2_input} = :gen_tcp.recv(socket, 50, 3000)
    {:ok, n} = Noise.act2(n, act2_input)
    {:ok, n, output} = Noise.act3(n)
    :ok = :gen_tcp.send(socket, output)

    state = Map.put(state, :noise, n)
    {:ok, %{state | handshake: :done}}
  end

  defp handshake(%{role: :responder, socket: socket} = state) do
    {:ok, n} = Noise.new(:responder, state[:key], [])
    {:ok, act1_input} = :gen_tcp.recv(socket, 50, 3000)
    {:ok, n} = Noise.act1(n, act1_input)
    {:ok, n, output} = Noise.act2(n)
    :ok = :gen_tcp.send(socket, output)
    {:ok, act3_input} = :gen_tcp.recv(socket, 66, 3000)
    {:ok, n} = Noise.act3(n, act3_input)

    state = Map.put(state, :noise, n)
    {:ok, %{state | handshake: :done}}
  end

  def active_once(%{transport: transport, socket: socket}), do: transport.setopts(socket, [{:active, :once}])
  def active_once(%{socket: socket}), do: :inet.setopts(socket, active: :once)

end

defmodule Volta.PeerListener do
  alias Volta.PeerConn

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
