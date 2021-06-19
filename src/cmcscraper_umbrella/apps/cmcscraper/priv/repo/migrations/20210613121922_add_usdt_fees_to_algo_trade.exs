defmodule Cmcscraper.Repo.Migrations.AddUsdtFeesToAlgoTrade do
  use Ecto.Migration

  def change do
    alter table("algo_trade") do
      add :fee_usdt,    :decimal,   null: true
    end
  end
end
