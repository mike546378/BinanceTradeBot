defmodule Cmcscraper.Repo do
  use Ecto.Repo,
    otp_app: :cmcscraper,
    adapter: Ecto.Adapters.Postgres

    def init(_, config) do
      {:ok, config}
    end
end
