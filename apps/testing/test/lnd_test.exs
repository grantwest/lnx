defmodule Volta.Testing.LNDTest do
  use ExUnit.Case, async: true
  alias Volta.KeyUtils
  alias Volta.Testing.LND
  alias Volta.Testing.Bitcoind

  @tag :slow
  test "start and initialize lnd" do
    {:ok, bitcoind} = Bitcoind.start_link()
    {:ok, lnd} = LND.start_link([bitcoind: [pid: bitcoind]])
    
    LND.wait_for_ready(lnd)
    assert KeyUtils.valid_public_key?(LND.state(lnd)[:identity_pubkey])

    LND.stop(lnd)
    Bitcoind.stop(bitcoind)
  end

end
