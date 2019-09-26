defmodule Pomodoro.MixProject do
  use Mix.Project

  def project do
    [
      app: :pomodoro,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: Mix.compilers() ++ [:boundary]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PomodoroUi, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      dep(:boundary, :github),
      dep(:cortex, :path),
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.1"},
      {:httpoison, "~> 1.5"},
      {:sched_ex, "~> 1.1"},
      dep(:scenic, :hex),
      {:scenic_driver_glfw, "~> 0.10"},
      {:scenic_live_reload, "~> 0.1.0"},
      {:slack, "~> 0.19"}
    ]
  end

  defp dep(:boundary, :github), do: {:boundary, github: "sasa1977/boundary"}
  defp dep(:boundary, :path), do: {:boundary, path: "../forks/boundary"}

  defp dep(:scenic, :hex), do: {:scenic, "~> 0.10"}
  defp dep(:scenic, :path), do: {:scenic, path: "../forks/scenic", override: true}

  defp dep(:cortex, :path), do: {:cortex, path: "../forks/cortex", only: [:dev, :test]}
  defp dep(:cortex, :hex), do: {:cortex, "~> 0.5", only: [:dev, :test]}
end
