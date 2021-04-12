defmodule Cmcscraper.Repo.Migrations.AddPeakPriceToPortfolio do
  use Ecto.Migration

  def change do
    alter table("portfolio") do
      add :peak_price, :decimal, null: false
    end
  end
end
