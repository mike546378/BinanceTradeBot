defmodule Cmcscraper.Repo.Migrations.ChangeFeeStructure do
  use Ecto.Migration

  def change do
    alter table("algo_trade") do
       remove :fee_usdt
       remove :fee_asset
       remove :fee_volume
       add :buy_fee_usdt,   :decimal,   null: true
       add :sell_fee_usdt,  :decimal,   null: true
    end
  end
end
