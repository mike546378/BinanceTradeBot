defmodule Cmcscraper.Schemas.HistoricPrice do
  use Ecto.Schema
  import Ecto.Changeset

  schema "historic_price" do
    field :date, :date
    field :volume, :decimal
    field :marketcap, :decimal
    field :price, :decimal
    field :ranking, :integer
    belongs_to :currency, Cmcscraper.Schemas.Currency
    timestamps()
  end

  def changeset(historic_price, params \\ %{}) do
    historic_price
    |> cast(params, [:date, :volume, :marketcap, :price, :currency_id, :ranking])
    |> validate_required([:date, :volume, :marketcap, :price, :currency_id, :ranking])
    |> unique_constraint(:date, name: :historic_price_once_per_date)
    |> foreign_key_constraint(:currency_id)
    |> assoc_constraint(:currency)
  end

  def to_dto(%__MODULE__{} = map) do
    %{
      "date" => map.date,
      "volume" => map.volume,
      "marketcap" => map.marketcap,
      "price" => map.price,
      "ranking" => map.ranking,
      "dateCreated" => map.inserted_at,
      "dateUpdated" => map.updated_at,
    }
  end

  def to_dto(nil) do
    nil
  end

end
