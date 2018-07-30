defmodule MaxwellCache.Mixfile do
  use Mix.Project

  def project do
    [
      app: :maxwell_cache,
      version: "0.1.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
    ]
  end

  defp description do
    """
    Maxwell middleware to cache success response.
    """
  end

  def application do
    [
      mod: {MaxwellCache.Application, []},
      extra_applications: applications(Mix.env)
    ]
  end

  defp applications(:test), do: [:logger, :poison, :ibrowse]
  defp applications(_),     do: [:logger]

  defp deps do
    [
      {:cachex, "~> 2.1"},
      {:maxwell, "~> 2.2"},
      {:ibrowse, "~> 4.2",          only: [:test]},
      {:poison, "~> 2.1 or ~> 3.0", only: [:test]},
    ]
  end
end
