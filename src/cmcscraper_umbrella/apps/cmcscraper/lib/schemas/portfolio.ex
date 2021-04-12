defmodule Cmcscraper.Schemas.Portfolio do
  alias Cmcscraper.Schemas.Currency
  use Ecto.Schema
  import Ecto.Changeset

  schema "portfolio" do
    field :purchase_date, :utc_datetime
    field :purchase_price, :decimal
    field :percentage_change_requirement, :decimal
    field :volume, :decimal
    field :sell_price, :decimal
    field :sell_date, :utc_datetime
    field :profit, :decimal
    field :peak_price, :decimal
    belongs_to :currency, Currency
    timestamps()
  end

  def changeset(historic_price, params \\ %{}) do
    historic_price
    |> cast(params, [:purchase_date, :purchase_price, :peak_price, :percentage_change_requirement, :volume, :sell_price, :sell_date, :profit, :currency_id])
    |> clear_errors()
    |> validate_required([:purchase_date, :purchase_price, :peak_price, :percentage_change_requirement, :volume, :currency_id])
    |> foreign_key_constraint(:currency_id)
    |> assoc_constraint(:currency)
  end

    def to_dto(%__MODULE__{} = map) do
    %{
      "id" => map.id,
      "purchaseDate" => map.purchase_date,
      "purchasePrice" => map.purchase_price,
      "percentageChangeRequirement" => map.percentage_change_requirement,
      "volume" => map.volume,
      "sellPrice" => map.sell_price,
      "sellDate" => map.sell_date,
      "profit" => map.profit,
      "peakPrice" => map.peak_price,
      "dateCreated" => map.inserted_at,
      "dateUpdated" => map.updated_at,
      "currency" => Currency.to_dto(map.currency)
    }
  end

  def to_dto(nil) do
    nil
  end

  defp clear_errors(%Ecto.Changeset{} = changeset) do
    Map.replace!(changeset, :errors, [])
    |> Map.replace!(:valid?, true)
  end
end
