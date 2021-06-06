defmodule Cmcscraper.Repo.Migrations.AddTickerPricesTable do
  use Ecto.Migration

  def change do
    create table("ticker_prices") do
      add :symbol,    :string, size: 10
      add :price,     :float
      add :datetime,  :utc_datetime
      timestamps()
    end
  end
end
