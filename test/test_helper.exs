ExUnit.configure(exclude: [:slow, :external, :todo])
Lnx.Testing.PortAllocator.ensure_started()
ExUnit.start()
