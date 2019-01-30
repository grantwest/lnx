defmodule Volta.Testing.Bitcoind do
  use GenServer
  alias Volta.Testing.PortAllocator

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def state(pid) do
    GenServer.call(pid, :get_state)
  end

  def mine_blocks(pid, opts \\ []) do
    GenServer.call(pid, {:mine_blocks, opts})
  end

  def stop(pid) do
    GenServer.stop(pid, :normal)
  end

  defp download(state) do
    version = state[:bitcoind_version]
    tar_url = "https://bitcoincore.org/bin/bitcoin-core-#{version}/bitcoin-#{version}-x86_64-linux-gnu.tar.gz"
    tar_name = "bitcoin-#{version}-x86_64-linux-gnu.tar.gz"
    folder_name = "bitcoin-#{version}"
    download_tar(tar_url, Path.join("/src/resources", tar_name))
    extract_tar(tar_name, folder_name)
  end

  defp set_defaults(opts) do
    state = 
    Enum.into(opts, %{})
    |> Map.put_new(:bitcoind_version, "0.17.1")
    |> Map.put_new(:name_prefix, "noname")
    |> Map.put_new(:random_hex, Base.encode16(<<:rand.uniform(4_000_000_000)::unsigned-size(32)>>, case: :lower))
    |> Map.put_new(:peer_port, PortAllocator.new_port())
    |> Map.put_new(:rpc_port, PortAllocator.new_port())
    |> Map.put_new(:zmqpubrawblock_port, PortAllocator.new_port())
    |> Map.put_new(:zmqpubrawtx_port, PortAllocator.new_port())

    prefix = state[:name_prefix]
    version = state[:bitcoind_version]
    random_hex = state[:random_hex]
    random_name = "#{prefix}_bitcoind_#{version}_#{random_hex}"

    state
    |> Map.put_new(:random_name, random_name)
    |> Map.put_new(:data_dir, "/src/temp/#{random_name}")
    |> Map.put_new(:bitcoind_path, "/src/resources/bitcoin-#{version}/bin/bitcoind")
    |> Map.put_new(:bitcoin_cli_path, "/src/resources/bitcoin-#{version}/bin/bitcoin-cli")
  end

  defp bitcoind_args(state) do
    Enum.join([
      "-regtest",
      "-datadir=#{state[:data_dir]}",
      "-bind=127.0.0.1",
      # "-discover=0",
      "-dns=0",
      "-dnsseed=0",
      # "-externalip=127.0.0.1",
      "-listen=1",
      "-port=#{state[:peer_port]}",
      "-disablewallet",
      "-logips=1",
      "-rpcallowip=127.0.0.1",
      "-rpcbind=127.0.0.1:#{state[:rpc_port]}",
      "-rpcuser=user",
      "-rpcpassword=password",
      "-zmqpubrawblock=tcp://127.0.0.1:#{state[:zmqpubrawblock_port]}",
      "-zmqpubrawtx=tcp://127.0.0.1:#{state[:zmqpubrawtx_port]}",
    ], " ")
  end

  defp bitcoin_cli(args, state) do
    global_options = [
      "-regtest",
      "-rpcconnect=127.0.0.1",
      "-rpcport=#{state[:rpc_port]}",
      "-rpcuser=user",
      "-rpcpassword=password",
      "-datadir=#{state[:data_dir]}",
      "-rpcwait",
    ]
    {stdout, _exit_code} = System.cmd(state[:bitcoin_cli_path], global_options ++ args, [])
    stdout
  end

  def init(opts) do
    state = set_defaults(opts)
    File.mkdir_p!(state[:data_dir])
    download(state)
    port = Port.open(
      {:spawn, "/src/resources/safe_start.sh #{state[:bitcoind_path]} #{bitcoind_args(state)}"}, 
      [:binary]
    )
       
    {:ok, Map.put(state, :port, port)}
  end
  
  def handle_info({port, {:data, msg}}, state) do
    name = state[:random_name]
    String.splitter(msg, "\n", [trim: true])
    |> Enum.map(fn l -> "#{name}: #{l}" end)
    |> Enum.each(fn _l -> nil end)
    {:noreply, state}
  end

  def handle_call({:mine_blocks, opts}, _from, state) do
    num_blocks = Keyword.get(opts, :count, 1)
    _json = bitcoin_cli(["generatetoaddress", "#{num_blocks}", "n4MN27Lk7Yh3pwfjCiAbRXtRVjs4Uk67fG"], state)
    {:reply, :ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def terminate(_reason, %{port: port}) do
    unless Port.info(port) == nil do
      true = Port.close(port)
    end
  end

  defp download_tar(tar_url, tar_path) do
    unless File.exists?(tar_path) do
      System.cmd("/usr/bin/wget", [tar_url], [cd: "/src/resources"])
    end
  end

  defp extract_tar(tar_name, folder_name) do
    unless File.exists? Path.join("/src/resources", folder_name) do
      System.cmd("/bin/tar", ["-xf", tar_name], [cd: "/src/resources"])
    end
  end
end
