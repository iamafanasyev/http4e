defmodule Http4e.MixProject do
  use Mix.Project

  def project do
    [
      app: :http4e,
      version: "0.2.0",
      elixir: "~> 1.0",
      deps: deps(),
    ]
  end

  def application do
    [
      extra_applications: [
        :inets,
      ],
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:freedom_formatter, "~> 1.0", only: [:dev], runtime: false},
    ]
  end
end
