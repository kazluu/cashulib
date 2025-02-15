defmodule Cashu.MixProject do
  use Mix.Project

  def project do
    [
      app: :cashu,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bitcoinex, "~> 0.1.7"},
      {:jason, "~> 1.4.1"},
      {:cbor, "~> 1.0.1"}
    ]
  end
end
