defmodule Timer.MixProject do
  use Mix.Project

  def project do
    [
      app: :timer,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Timer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "1.0.0-rc.6", only: :dev, runtime: false}
    ]
  end
end
