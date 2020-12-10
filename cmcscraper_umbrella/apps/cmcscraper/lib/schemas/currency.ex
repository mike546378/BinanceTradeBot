defmodule Cmcscraper.Schemas.Currency do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "currency" do
    field :currency_name, :string
    has_many :historic_price, Cmcscraper.Schemas.HistoricPrice
    timestamps()
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(currency, params \\ %{}) do
    currency
    |> cast(params, [:currency_name])
    |> unique_constraint(:currency_name)
  end

  def get_all() do
    from(self(), select: [:currency_name])
  end
end
