defmodule Cmcscraper.Schemas.TickerPrices do
  alias Cmcscraper.Models.BinanceApi
  use Ecto.Schema
  import Ecto.Changeset

  schema "ticker_prices" do
    field :datetime, :utc_datetime
    field :price, :float
    field :symbol, :string
    timestamps()
  end

  def changeset(ticker_price, params \\ %{}) do
    ticker_price
    |> cast(params, [:datetime, :price, :symbol])
    |> clear_errors()
    |> validate_required([:datetime, :price, :symbol])
  end

  defp clear_errors(%Ecto.Changeset{} = changeset) do
    Map.replace!(changeset, :errors, [])
    |> Map.replace!(:valid?, true)
  end

  def to_dto(%__MODULE__{} = map) do
    %{
      "datetime" => map.datetime,
      "price" => map.price,
      "symbol" => map.symbol,
      "dateCreated" => map.inserted_at,
      "dateUpdated" => map.updated_at,
    }
  end

  def to_dto(nil) do
    nil
  end

  def from_object(%BinanceApi.Ticker{} = ticker) do
    %__MODULE__{
      datetime: DateTime.utc_now(),
      price: String.to_float(ticker.price),
      symbol: ticker.symbol,
    }
  end

  def compare(%__MODULE__{} = item1, %__MODULE__{} = item2) when item1.ranking > item2.ranking, do: :gt
  def compare(%__MODULE__{} = item1, %__MODULE__{} = item2) when item1.ranking == item2.ranking, do: :eq
  def compare(%__MODULE__{} = item1, %__MODULE__{} = item2) when item1.ranking < item2.ranking, do: :lt
end
