defmodule Volta.Testing.PortAllocator do
  use GenServer

  def ensure_started() do
    case Process.whereis(:singleton_port_allocator) do
      nil -> start_link()
      pid -> {:ok, pid}
    end
  end

  def new_port(port_allocator \\ :singleton_port_allocator) do
    pid = Process.whereis(port_allocator)
    GenServer.call(pid, :new_port)
  end
  
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, :singleton_port_allocator)
    GenServer.start_link(__MODULE__, opts, [name: name])
  end

  def init(_opts) do
    first_port = :rand.uniform(20) * 1000
    {:ok, %{next_port: first_port}}
  end

  def handle_call(:new_port, _from, state) do
    port = state[:next_port]
    state = Map.update!(state, :next_port, &(&1 + 1))
    {:reply, port, state}
  end

end
