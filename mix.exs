defmodule OffBroadwayEcto.MixProject do
  use Mix.Project

  def project do
    [
      app: :off_broadway_ecto,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:broadway, "~> 1.0.0"},
      {:ecto_sql, "~> 3.9"},
      {:postgrex, "~> 0.14", only: :test},
      {:nimble_options, "~> 0.4.0"}
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
