defmodule Cmcscraper.RepoFunctions.CurrencyRepository do
  import Ecto.Query
  alias Cmcscraper.Repo
  alias Cmcscraper.Schemas.Currency
  alias Cmcscraper.Schemas.HistoricPrice

  def add_update_currency(%Currency{} = currency) do
    case Repo.get_by(Currency, currency_name: currency.currency_name) do
      nil ->
        Currency.changeset(%Currency{})
      changeset -> changeset
    end
    |> Currency.changeset(Map.from_struct(currency))
    |> Repo.insert_or_update()
  end


  def get_all_currencies() do
    from(Currency)
    |> Repo.all()
  end

  def get_currency_by_name(name) do

    order_query =
      from p in HistoricPrice,
        select: %{id: p.id, row: row_number() |> over(:partition)},
        windows: [partition: [partition_by: :currency_id, order_by: :inserted_at]]

    price_query =
      from p in HistoricPrice,
        join: l in subquery(order_query),
          on: p.id == l.id and l.row <= 10

    Repo.one from c in Currency, where: [currency_name: ^name], limit: 1, preload: [historic_price: ^price_query]
  end

  def get_currency_by_symbol(symbol) do
    Repo.one from c in Currency, where: [symbol: ^symbol], limit: 1
  end

  def get_currency_data(limit, offset) when is_number(limit) and is_number(offset) do

    order_query =
      from p in HistoricPrice,
        select: %{id: p.id, row: row_number() |> over(:partition)},
        windows: [partition: [partition_by: :currency_id, order_by: :inserted_at]]

    price_query =
      from p in HistoricPrice,
        join: l in subquery(order_query),
          on: p.id == l.id and l.row <= 30

    Repo.all(from c in Currency, limit: ^limit, offset: ^offset, order_by: c.id, preload: [historic_price: ^price_query])
  end

  def to_dto(%Currency{} = currency) do
    %{
        "id" => currency.id,
        "name" => currency.currency_name,
        "dateCreated" => currency.inserted_at,
        "dateUpdated" => currency.updated_at,
        "priceData" => Enum.map(currency.historic_price, fn x -> HistoricPrice.to_dto(x) end)
    }
  end

  def to_dto(nil) do
    nil
  end
end
