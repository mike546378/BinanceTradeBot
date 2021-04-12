defmodule Cmcscraper.Repo.Migrations.AddPortfolioTable do
  use Ecto.Migration

  def change do
    alter table("currency") do
      add :symbol, :string, null: true
    end

    create table("portfolio") do
      add :currency_id,                   references("currency"), null: false
      add :purchase_date,                 :utc_datetime, null: false
      add :purchase_price,                :decimal, null: false
      add :percentage_change_requirement, :decimal, null: false
      add :volume,                        :decimal, null: false
      add :sell_price,                    :decimal, null: true
      add :sell_date,                     :utc_datetime, null: true
      add :profit,                        :decimal, null: true
      timestamps()
    end

  end
end
