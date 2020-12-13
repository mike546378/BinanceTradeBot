defmodule Cmcscraper.Repo.Migrations.AddCmcIdToCurrency do
  use Ecto.Migration

  def change do
    alter table("currency") do
      add :cmc_id, :integer, null: true
    end
  end
end
