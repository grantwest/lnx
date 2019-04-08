defmodule Lnx.Testing.LND do
  use GenServer
  alias Lnx.Testing.Bitcoind
  alias Lnx.Testing.PortAllocator

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def wait_for_ready(pid) do
    GenServer.call(pid, :wait_for_ready, 20000)
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def stop(pid) do
    GenServer.stop(pid, :normal)
  end

  defp download(state) do
    version = state[:lnd_version]

    tar_url =
      "https://github.com/lightningnetwork/lnd/releases/download/#{version}/lnd-linux-amd64-#{version}.tar.gz"

    tar_name = "lnd-linux-amd64-#{version}.tar.gz"
    folder_name = "lnd-linux-amd64-#{version}"
    download_tar(tar_url, Path.join("/src/resources", tar_name))
    extract_tar(tar_name, folder_name)
  end

  defp set_defaults(opts) do
    state =
      Enum.into(opts, %{})
      |> Map.put_new(:lnd_version, "v0.5.1-beta")
      |> Map.put_new(:name_prefix, "noname")
      |> Map.put_new(
        :random_hex,
        Base.encode16(<<:rand.uniform(4_000_000_000)::unsigned-size(32)>>, case: :lower)
      )
      |> Map.put_new(:peer_port, PortAllocator.new_port())
      |> Map.put_new(:rpc_port, PortAllocator.new_port())
      |> Map.put_new(:rest_port, PortAllocator.new_port())

    prefix = state[:name_prefix]
    version = state[:lnd_version]
    random_hex = state[:random_hex]
    random_name = "#{prefix}_lnd_#{version}_#{random_hex}"

    state
    |> Map.put_new(:random_name, random_name)
    |> Map.put_new(:lnd_dir, "/src/temp/#{random_name}")
    |> Map.put_new(:lnd_path, "/src/resources/lnd-linux-amd64-#{version}/lnd")
    |> Map.put_new(:lncli_path, "/src/resources/lnd-linux-amd64-#{version}/lncli")
  end

  defp lnd_args(state) do
    args =
      Enum.join(
        [
          "--lnddir=#{state[:lnd_dir]}",
          "--debuglevel=trace",
          "--listen=127.0.0.1:#{state[:peer_port]}",
          "--rpclisten=127.0.0.1:#{state[:rpc_port]}",
          "--restlisten=127.0.0.1:#{state[:rest_port]}",
          "--externalip=127.0.0.1:#{state[:peer_port]}",
          "--nobootstrap",
          "--alias=#{state[:random_name]}",
          "--bitcoin.active",
          "--bitcoin.regtest"
        ] ++ bitcoind_args(state),
        " "
      )

    args
  end

  defp bitcoind_args(state) do
    bitcoind_pid = state[:bitcoind][:pid]
    bitcoind_state = Bitcoind.state(bitcoind_pid)

    [
      "--bitcoin.node=bitcoind",
      "--bitcoind.dir=#{bitcoind_state[:data_dir]}",
      "--bitcoind.rpchost=127.0.0.1:#{bitcoind_state[:rpc_port]}",
      "--bitcoind.rpcuser=user",
      "--bitcoind.rpcpass=password",
      "--bitcoind.zmqpubrawblock=tcp://127.0.0.1:#{bitcoind_state[:zmqpubrawblock_port]}",
      "--bitcoind.zmqpubrawtx=tcp://127.0.0.1:#{bitcoind_state[:zmqpubrawtx_port]}"
    ]
  end

  def init(opts) do
    state = set_defaults(opts)
    File.mkdir_p!(state[:lnd_dir])
    download(state)

    port =
      Port.open({:spawn, "/src/resources/safe_start.sh #{state[:lnd_path]} #{lnd_args(state)}"}, [
        :binary
      ])

    state =
      state
      |> Map.put(:port, port)
      |> Map.put(:status, :starting)

    {:ok, state}
  end

  def handle_info({_port, {:data, msg}}, %{random_name: name} = state) do
    state =
      String.splitter(msg, "\n", trim: true)
      |> Enum.map(fn l -> "#{name}: #{l}" end)
      |> Enum.reduce(state, fn l, s -> do_action(l, s) end)

    {:noreply, state}
  end

  def handle_call(:wait_for_ready, _from, %{status: :ready} = state) do
    {:reply, :ok, state}
  end

  def handle_call(:wait_for_ready, from, state) do
    state = Map.update(state, :waiters, [from], &[from | &1])
    {:noreply, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def terminate(_reason, %{port: port}) do
    unless Port.info(port) == nil do
      true = Port.close(port)
    end
  end

  defp do_action(msg, state) do
    [
      {~r/Waiting for wallet encryption password\./, &init_wallet/1},
      {~r/Finished rescan for 0 addresses/, &get_info_and_notify_waiters/1}
    ]
    |> Enum.filter(fn {regex, _action} -> Regex.match?(regex, msg) end)
    |> Enum.reduce(state, fn {_, action}, s -> action.(s) end)
  end

  defp init_wallet(state) do
    json = ~s"""
      {
        "wallet_password": "cGFzc3dvcmQ=",
        "cipher_seed_mnemonic": [
          "absorb",
          "divorce",
          "matter",
          "disagree",
          "fine",
          "rabbit",
          "virus",
          "canyon",
          "cradle",
          "debris",
          "switch",
          "match",
          "column",
          "core",
          "bright",
          "baby",
          "soap",
          "curve",
          "split",
          "famous",
          "crystal",
          "giant",
          "bullet",
          "sorry"
        ],
        "aezeed_passphrase": "",
        "recovery_window": 0
      }
    """

    {:ok, resp} =
      HTTPoison.post("https://127.0.0.1:#{state[:rest_port]}/v1/initwallet", json, [],
        ssl: [verify: :verify_none]
      )

    200 = resp.status_code
    state
  end

  defp get_info_and_notify_waiters(state) do
    state
    |> get_info()
    |> reply_to_waiters()
  end

  defp get_info(state) do
    output = lncli(["getinfo"], state)
    info = Poison.decode!(output)
    key = Base.decode16!(info["identity_pubkey"], case: :mixed)

    state
    |> Map.put(:identity_pubkey, key)
  end

  defp reply_to_waiters(state) do
    Map.get(state, :waiters, [])
    |> Enum.each(fn waiter -> GenServer.reply(waiter, :ok) end)

    state
    |> Map.put(:waiters, [])
    |> Map.put(:status, :ready)
  end

  defp lncli(args, state) do
    global_options = [
      "--rpcserver=127.0.0.1:#{state[:rpc_port]}",
      "--lnddir=#{state[:lnd_dir]}",
      "--network=regtest"
      # "--macaroonpath=#"
    ]

    {stdout, _exit_code} = System.cmd(state[:lncli_path], global_options ++ args, [])
    # {stdout, 0} = System.cmd("pwd", [], [])
    stdout
  end

  defp download_tar(tar_url, tar_path) do
    unless File.exists?(tar_path) do
      System.cmd("/usr/bin/wget", [tar_url], cd: "/src/resources")
    end
  end

  defp extract_tar(tar_name, folder_name) do
    unless File.exists?(Path.join("/src/resources", folder_name)) do
      System.cmd("/bin/tar", ["-xf", tar_name], cd: "/src/resources")
    end
  end
end
