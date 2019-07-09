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
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:launcher, path: "../../launcher"},
      {:scenic, "~> 0.10"},
      {:timer_core, path: "../timer_core"}
    ]
  end
end
