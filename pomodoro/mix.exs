defmodule Pomodoro.MixProject do
  use Mix.Project

  def project do
    [
      app: :pomodoro,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: compilers(Mix.env())
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
      dep(:boundary, :hex),
      # dep(:cortex, :path),
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      dep(:priv_check, :hex),
      {:jason, "~> 1.1"},
      {:httpoison, "~> 1.6"},
      dep(:launcher, :github),
      {:sched_ex, "~> 1.1"},
      dep(:scenic, :github),
      dep(:scenic_driver_glfw, :github),
      dep(:scenic_live_reload, :path),
      {:exsync, path: "~/dev/forks/exsync", only: :dev, override: true},
      {:truetype_metrics, "~> 0.5.1"},
      {:slack, "~> 0.19"}
    ]
  end

  defp dep(:launcher, :github), do: {:launcher, github: "axelson/scenic_launcher"}
  defp dep(:launcher, :path), do: {:launcher, path: "~/dev/launcher"}

  defp dep(:boundary, :hex), do: {:boundary, "~> 0.8"}
  defp dep(:boundary, :github), do: {:boundary, github: "sasa1977/boundary"}
  defp dep(:boundary, :path), do: {:boundary, path: "../forks/boundary"}

  defp dep(:scenic, :hex), do: {:scenic, "~> 0.10"}

  defp dep(:scenic, :github),
    do: {:scenic, github: "boydm/scenic", branch: "v0.11", override: true}

  defp dep(:scenic, :path), do: {:scenic, path: "../forks/scenic", override: true}

  defp dep(:scenic_driver_glfw, :hex), do: {:scenic_driver_glfw, "~> 0.10", only: :dev}

  defp dep(:scenic_driver_glfw, :github),
    do:
      {:scenic_driver_glfw,
       github: "boydm/scenic_driver_glfw", branch: "v0.11", only: :dev, override: true}

  defp dep(:scenic_driver_glfw, :path),
    do: {:scenic_driver_glfw, path: "../forks/scenic_driver_glfw", only: :dev, override: true}

  defp dep(:scenic_live_reload, :hex), do: {:scenic_live_reload, "~> 0.2.0", only: :dev}

  defp dep(:scenic_live_reload, :path),
    do: {:scenic_live_reload, path: "../scenic_live_reload", only: :dev}

  defp dep(:cortex, :path), do: {:cortex, path: "../forks/cortex", only: [:dev, :test]}
  defp dep(:cortex, :hex), do: {:cortex, "~> 0.5", only: [:dev, :test]}

  defp dep(:priv_check, :hex), do: {:priv_check, "~> 0.2", only: [:dev, :test], runtime: false}

  defp dep(:priv_check, :path),
    do: {:priv_check, path: "~/dev/priv_check", only: [:dev, :test], runtime: false}

  defp compilers(:prod), do: [:boundary] ++ Mix.compilers()
  # defp compilers(_), do: [:boundary, :priv_check] ++ Mix.compilers()
  defp compilers(_), do: [:boundary] ++ Mix.compilers()
end