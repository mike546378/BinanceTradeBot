defmodule Cmcscraper.Schemas.HistoricPrice do
  alias Cmcscraper.Models.CmcApi
  alias Cmcscraper.Schemas.Currency
  use Ecto.Schema
  import Ecto.Changeset

  schema "historic_price" do
    field :date, :date
    field :volume, :decimal
    field :marketcap, :decimal
    field :price, :decimal
    field :ranking, :integer
    belongs_to :currency, Currency
    timestamps()
  end

  def changeset(historic_price, params \\ %{}) do
    historic_price
    |> cast(params, [:date, :volume, :marketcap, :price, :currency_id, :ranking])
    |> clear_errors()
    |> validate_required([:date, :volume, :marketcap, :price, :currency_id, :ranking])
    |> unique_constraint(:date, name: :historic_price_once_per_date)
    |> foreign_key_constraint(:currency_id)
    |> assoc_constraint(:currency)
  end

  defp clear_errors(%Ecto.Changeset{} = changeset) do
    Map.replace!(changeset, :errors, [])
    |> Map.replace!(:valid?, true)
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

  def from_object(%CmcApi.CmcCoin{} = cmc_coin) do
    %CmcApi.CmcQuoteDetails{} = price_details = cmc_coin.quote.usd
    %__MODULE__{
      currency: Currency.from_object(cmc_coin),
      volume: price_details.volume_24h,
      marketcap: price_details.market_cap,
      price: price_details.price,
      ranking: cmc_coin.cmc_rank,
      date: price_details.last_updated |> NaiveDateTime.to_date()
    }
  end

  def compare(%__MODULE__{} = item1, %__MODULE__{} = item2) when item1.ranking > item2.ranking, do: :gt
  def compare(%__MODULE__{} = item1, %__MODULE__{} = item2) when item1.ranking == item2.ranking, do: :eq
  def compare(%__MODULE__{} = item1, %__MODULE__{} = item2) when item1.ranking < item2.ranking, do: :lt
end
