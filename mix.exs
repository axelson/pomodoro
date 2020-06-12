defmodule Pomodoro.MixProject do
  use Mix.Project

  def project do
    [
      app: :pomodoro,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:boundary, :priv_check] ++ Mix.compilers()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PomodoroUi, []},
      # Add poison to work around
      # https://github.com/BlakeWilliams/Elixir-Slack/issues/195
      extra_applications: [:logger, :poison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      dep(:boundary, :hex),
      # dep(:cortex, :path),
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},
      dep(:priv_check, :path),
      {:jason, "~> 1.1"},
      {:httpoison, "~> 1.6"},
      {:launcher, github: "axelson/scenic_launcher"},
      {:sched_ex, "~> 1.1"},
      dep(:scenic, :hex),
      {:scenic_driver_glfw, "~> 0.10", only: :dev},
      dep(:scenic_live_reload, :hex),
      # {:exsync, path: "~/dev/forks/exsync", only: :dev, override: true},
      {:slack, "~> 0.19"}
    ]
  end

  defp dep(:boundary, :hex), do: {:boundary, "~> 0.4.0"}
  defp dep(:boundary, :github), do: {:boundary, github: "sasa1977/boundary"}
  defp dep(:boundary, :path), do: {:boundary, path: "../forks/boundary"}

  defp dep(:scenic, :hex), do: {:scenic, "~> 0.10"}
  defp dep(:scenic, :path), do: {:scenic, path: "../forks/scenic", override: true}

  defp dep(:scenic_live_reload, :hex), do: {:scenic_live_reload, "~> 0.2.0", only: :dev}

  defp dep(:scenic_live_reload, :path),
    do: {:scenic_live_reload, path: "../scenic_live_reload", only: :dev}

  defp dep(:cortex, :path), do: {:cortex, path: "../forks/cortex", only: [:dev, :test]}
  defp dep(:cortex, :hex), do: {:cortex, "~> 0.5", only: [:dev, :test]}

  defp dep(:priv_check, :hex), do: {:priv_check, "~> 0.1", only: [:dev, :test], runtime: false}

  defp dep(:priv_check, :path),
    do: {:priv_check, path: "~/dev/priv_check", only: [:dev, :test], runtime: false}
end
