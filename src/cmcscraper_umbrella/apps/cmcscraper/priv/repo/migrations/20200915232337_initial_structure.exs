defmodule Cmcscraper.Repo.Migrations.InitialStructure do
  use Ecto.Migration

  def change do
      create table("currency") do
        add :currency_name,      :string, size: 100
        timestamps()
      end

      create table("historic_price") do
        add :currency_id, references("currency"), null: false
        add :date,      :date, null: false
        add :volume,    :decimal, null: false
        add :marketcap, :decimal, null: false
        add :price,     :decimal, null: false
        timestamps()
      end

      create unique_index("currency", [:currency_name])
      create unique_index("historic_price", [:currency_id, :date], name: :historic_price_once_per_date)
  end
end
