defmodule Cmcscraper.Schemas.Currency do
  alias Cmcscraper.Models.CmcApi
  use Ecto.Schema
  import Ecto.Changeset

  schema "currency" do
    field :currency_name, :string
    field :cmc_id, :integer
    has_many :historic_price, Cmcscraper.Schemas.HistoricPrice
    timestamps()
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(currency, params \\ %{}) do
    currency
    |> cast(params, [:currency_name, :cmc_id])
    |> unique_constraint(:currency_name)
  end


  def from_object(%CmcApi.CmcCoin{} = cmc_coin) do
    %__MODULE__{
      currency_name: cmc_coin.slug,
      cmc_id: cmc_coin.id,
    }
  end
end
