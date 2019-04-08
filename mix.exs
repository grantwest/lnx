defmodule LNX.MixProject do
  use Mix.Project

  def project do
    [
      app: :lnx,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {LNX.Application, []}
    ]
  end

  defp deps do
    [
      {:enacl, "~> 0.17.2"},
      {:hkdf, "~> 0.1.0"},
      {:httpoison, "~> 1.5", only: :test},
      {:libsecp256k1, "~> 0.1.10"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:poison, "~> 4.0", only: :test},
      {:ranch, "~> 1.7"}
    ]
  end
end
