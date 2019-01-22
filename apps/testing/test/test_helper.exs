File.ls!("/src/temp")
|> Enum.filter(fn p -> File.dir?("/src/temp/#{p}") end)
|> Enum.each(fn d -> File.rm_rf!("/src/temp/#{d}") end)

ExUnit.configure exclude: [:slow, :external, :todo] 
Volta.Testing.PortAllocator.ensure_started()
ExUnit.start()
