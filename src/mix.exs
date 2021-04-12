defmodule Cmcscraper.MixProject do
  use Mix.Project

  def project do
    [
      app: :interactiveshell,
      version: "1.0.0",
      deps: deps(),
      deps_path: "cmcscraper_umbrella/deps",
      lockfile: "cmcscraper_umbrella/mix.lock",
      build_path: "cmcscraper_umbrella/_build",
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:httpoison, "~> 1.4"},
      {:floki, "~> 0.20.0"},
      {:decimal, "~> 2.0"}
    ]
  end
end
