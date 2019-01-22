defmodule Volta.Testing.BitcoindTest do
  use ExUnit.Case, async: true
  alias Volta.Testing.Bitcoind

  @tag :slow
  test "start and initialize bitcoind" do
    {:ok, bitcoind} = Bitcoind.start_link()

    Bitcoind.mine_blocks(bitcoind, count: 1)
    
    Bitcoind.stop(bitcoind)
  end

end
