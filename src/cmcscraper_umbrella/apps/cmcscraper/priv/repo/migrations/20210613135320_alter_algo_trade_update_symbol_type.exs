defmodule Cmcscraper.Repo.Migrations.AlterAlgoTradeUpdateSymbolType do
  use Ecto.Migration

  def change do
    alter table("algo_trade") do
      modify :symbol, :string, size: 30
    end
  end
end
