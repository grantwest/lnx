defmodule Volta.Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ranch]
    ]
  end

  defp deps do
    [
      {:puppeteer, only: :dev, in_umbrella: true},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:hkdf, "~> 0.1.0"},
      {:enacl, "~> 0.17.2"},
      {:libsecp256k1, "~> 0.1.10"},
      {:ranch, "~> 1.7"},
    ]
  end
end
