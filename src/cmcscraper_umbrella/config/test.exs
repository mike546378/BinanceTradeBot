use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cmcscraper_web, CmcscraperWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

import_config "dev.secret.exs"

config :cmcscraper, Cmcscraper.Repo,
  username: "postgres",
  password: "postgres",
  database: "cmcscraper_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :cmcscraper,
  env: :test,
  cmc_api_uri: "https://sandbox-api.coinmarketcap.com/",
  binance_api_uri: System.get_env("BINANCE_API_URI") || "https://api.binance.com/api/"
