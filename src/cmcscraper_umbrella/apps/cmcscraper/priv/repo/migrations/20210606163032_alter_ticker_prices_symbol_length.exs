defmodule Cmcscraper.Repo.Migrations.AlterTickerPricesSymbolLength do
  use Ecto.Migration

  def change do
    alter table("ticker_prices") do
      modify :symbol, :string, size: 30
    end
  end
end
