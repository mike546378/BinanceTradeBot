defmodule Cmcscraper.Repo.Migrations.AlgoTradingTables do
  use Ecto.Migration

  def change do
    create table("algo_strategy") do
      add :sell_low,              :decimal,        null: false
      add :sell_high,             :decimal,        null: false
      add :ticks_count,           :integer,        null: false
      add :percentage_change,     :decimal,        null: false
      add :purchase_size,         :decimal,        null: false
      add :profit,                :decimal,        null: false
      add :is_active,             :boolean,        null: false
      timestamps()
    end

    create table("algo_trade") do
      add :purchase_date,         :utc_datetime,  null: false
      add :purchase_price,        :decimal,       null: false
      add :symbol,                :decimal,       null: false
      add :volume,                :decimal,       null: false
      add :sell_price,            :decimal,       null: true
      add :sell_date,             :utc_datetime,  null: true
      add :algo_strategy_id,      references("algo_strategy"), null: false
      timestamps()
    end

    create index("algo_trade", [:algo_strategy_id])
    create index("ticker_prices", [:datetime])
  end
end
