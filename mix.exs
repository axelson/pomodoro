defmodule Pomodoro.MixProject do
  use Mix.Project

  def project do
    [
      app: :pomodoro,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: Mix.compilers() ++ [:boundary],
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
      {:boundary, github: "sasa1977/boundary"},
      {:scenic, "~> 0.10"},
      {:scenic_driver_glfw, "~> 0.10"}
    ]
  end
end
