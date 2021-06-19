defmodule Cmcscraper.Repo.Migrations.AddFeeInfoToAlgoTrade do
  use Ecto.Migration

  def change do
    alter table("algo_trade") do
      add :fee_volume,  :decimal,   null: true
      add :fee_asset,   :string,    null: true
    end
  end
end
