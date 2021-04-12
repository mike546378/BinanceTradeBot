defmodule Cmcscraper.Schemas.Currency do
  alias Cmcscraper.Models.CmcApi
  alias Cmcscraper.Schemas
  use Ecto.Schema
  import Ecto.Changeset

  schema "currency" do
    field :currency_name, :string
    field :cmc_id, :integer
    field :symbol, :string
    has_many :historic_price, Schemas.HistoricPrice
    timestamps()
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(currency, params \\ %{}) do
    currency
    |> cast(params, [:currency_name, :cmc_id, :symbol])
    |> unique_constraint(:currency_name)
  end


  def from_object(%CmcApi.CmcCoin{} = cmc_coin) do
    %__MODULE__{
      currency_name: cmc_coin.slug,
      cmc_id: cmc_coin.id,
      symbol: cmc_coin.symbol
    }
  end

  def to_dto(%__MODULE__{} = currency) do
    %{
        "id" => currency.id,
        "name" => currency.currency_name,
        "symbol" => currency.symbol,
        "dateCreated" => currency.inserted_at,
        "dateUpdated" => currency.updated_at,
        "priceData" => map_price_data(currency.historic_price)
    }
  end

  def to_dto(_) do
    nil
  end

  defp map_price_data(price_data) when is_list(price_data) do
    Enum.map(price_data, fn x -> Schemas.HistoricPrice.to_dto(x) end)
  end

  defp map_price_data(_), do: nil
end
