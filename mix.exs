defmodule Http4e.MixProject do
  use Mix.Project

  def project do
    [
      app: :http4e,
      version: "0.1.0",
      elixir: "~> 1.13",
      deps: deps(),
    ]
  end

  def application do
    [
      extra_applications: [
        :inets,
        :logger,
      ],
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
    ]
  end
end
