defmodule MaxwellCache.Mixfile do
  use Mix.Project

  def project do
    [
      app: :maxwell_cache,
      version: "0.0.1",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:cachex, "~> 2.1"},
      {:maxwell, "~> 2.2"},
    ]
  end
end
