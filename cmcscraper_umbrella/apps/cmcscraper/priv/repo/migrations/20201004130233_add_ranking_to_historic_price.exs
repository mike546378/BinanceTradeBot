defmodule Cmcscraper.Repo.Migrations.AddRankingToHistoricPrice do
  use Ecto.Migration

  def change do
    alter table("historic_price") do
      add :ranking, :integer, null: false, default: -1
    end
  end
end
