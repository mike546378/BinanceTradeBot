# Jormungandr

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## dev.secret.exs
```
use Mix.Config

pg_host = "localhost"
pg_port = "5432"
pg_user = "postgres"
pg_password = "postgres"
pg_database = "cmcscraper"
cmc_api_key =
secret_key_base =

config :cmcscraper, Cmcscraper.Repo,
  username: System.get_env("PGUSER") || pg_user,
  password: System.get_env("PGPASSWORD") || pg_password,
  hostname: System.get_env("PGHOST") || pg_host,
  port: String.to_integer(System.get_env("PGPORT") || pg_port),
  database: System.get_env("PGDATABASE") || pg_database,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :cmcscraper,
  cmc_api_key: System.get_env("CMC_API_KEY") || cmc_api_key

secret_key_base = System.get_env("SECRET_KEY_BASE") || secret_key_base

config :cmcscraper_web, CmcscraperWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base
```