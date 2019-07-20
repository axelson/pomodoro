defmodule Timer.MixProject do
  use Mix.Project

  def project do
    [
      app: :timer,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Timer, []},
      extra_applications: [
        # Workaround Elixir-Slack issue:
        # https://github.com/BlakeWilliams/Elixir-Slack/pull/196
        :poison
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.0.0-rc.6", only: :dev, runtime: false},
      {:httpoison, "~> 1.5"},
      {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test]},
      {:jason, "~> 1.1"},
      # Pin until this is fixed: https://github.com/BlakeWilliams/Elixir-Slack/issues/181
      {:slack, github: "BlakeWilliams/Elixir-Slack", ref: "4812cf8"},
      dep(:launcher, :github),
      {:scenic, "~> 0.10"},
      {:timer_core, path: "../timer_core"}
    ]
  end

  defp dep(:launcher, :path), do: {:launcher, path: "../../launcher"}
  defp dep(:launcher, :github), do: {:launcher, github: "axelson/scenic_launcher"}
end
