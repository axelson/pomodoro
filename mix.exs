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
      mod: {Pomodoro.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:state_server, "~> 0.4.7"},
      {:finitomata, "~> 0.26.3"},
      {:machinery, "~> 1.1.0"},
      {:fsmx, "~> 0.5.0"},
      {:flex_test, path: "~/dev/flex_test", only: [:test]},
      dep(:boundary, :hex),
      # dep(:cortex, :path),
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      dep(:priv_check, :hex),
      {:happy_with, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:httpoison, "~> 2.0"},
      dep(:launcher, :github),
      {:sched_ex, "~> 1.1"},
      {:scenic_widget_contrib, path: "~/dev/forks/scenic-widget-contrib", override: true},
      dep(:scenic, :hex),
      dep(:scenic_driver_local, :hex),
      dep(:scenic_live_reload, :hex),
      {:ecto_sqlite3, "~> 0.17"},
      # {:exsync, path: "~/dev/forks/exsync", only: :dev, override: true},
      {:truetype_metrics, "~> 0.6"},
      {:muontrap, "~> 0.6.1 or ~> 1.0"},
      {:machete, "~> 0.3.3", only: [:test]}
    ]
  end

  defp dep(:launcher, :github), do: {:launcher, github: "axelson/scenic_launcher"}
  defp dep(:launcher, :path), do: {:launcher, path: "~/dev/launcher"}

  defp dep(:boundary, :hex), do: {:boundary, "~> 0.8"}
  defp dep(:boundary, :github), do: {:boundary, github: "sasa1977/boundary"}
  defp dep(:boundary, :path), do: {:boundary, path: "~/dev/forks/boundary"}

  defp dep(:scenic, :hex), do: {:scenic, "~> 0.11", override: true}

  defp dep(:scenic, :github),
    do: {:scenic, github: "boydm/scenic", branch: "v0.11", override: true}

  defp dep(:scenic, :path), do: {:scenic, path: "~/dev/forks/scenic", override: true}

  defp dep(:scenic_driver_local, :hex), do: {:scenic_driver_local, "~> 0.11.0", only: :dev, override: true}

  defp dep(:scenic_driver_local, :github),
    do:
      {:scenic_driver_local,
       github: "ScenicFramework/scenic_driver_local", branch: "main", only: :dev, override: true}

  defp dep(:scenic_driver_local, :path),
    do:
      {:scenic_driver_local, path: "~/dev/forks/scenic_driver_local", only: :dev, override: true}

  defp dep(:scenic_live_reload, :hex), do: {:scenic_live_reload, "~> 0.3", only: :dev}

  defp dep(:scenic_live_reload, :path),
    do: {:scenic_live_reload, path: "~/dev/scenic_live_reload", only: :dev}

  defp dep(:cortex, :path), do: {:cortex, path: "~/dev/forks/cortex", only: [:dev, :test]}
  defp dep(:cortex, :hex), do: {:cortex, "~> 0.5", only: [:dev, :test]}

  defp dep(:priv_check, :hex), do: {:priv_check, "~> 0.2", only: [:dev, :test], runtime: false}

  defp dep(:priv_check, :path),
    do: {:priv_check, path: "~/dev/priv_check", only: [:dev, :test], runtime: false}

  defp compilers(:prod), do: [:boundary] ++ Mix.compilers()
  # defp compilers(_), do: [:boundary, :priv_check] ++ Mix.compilers()
  defp compilers(_), do: [:boundary] ++ Mix.compilers()
end
