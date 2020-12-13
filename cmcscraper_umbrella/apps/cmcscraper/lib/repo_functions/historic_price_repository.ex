defmodule Cmcscraper.RepoFunctions.HistoricPriceRepository do
  import Ecto.Query
  alias Cmcscraper.Repo
  alias Cmcscraper.Schemas.HistoricPrice
  alias Cmcscraper.Schemas.Currency
  alias Cmcscraper.RepoFunctions.CurrencyRepository

  def insert_price([date = %Date{}, price, volume, marketcap], currency_id) do
    case Repo.get_by(HistoricPrice, [currency_id: currency_id, date: date]) do
      nil ->
        %HistoricPrice{}
      changeset -> changeset
    end
    |> HistoricPrice.changeset(%{date: date, volume: volume, price: price, marketcap: marketcap, currency_id: currency_id, ranking: 0 })
    |> Repo.insert_or_update!()
  end

  def get_price_data_by_currency_id(currency_id) do
    HistoricPrice
    |> where(currency_id: ^currency_id)
    |> Repo.all()
  end

  @spec update_todays_price(String.t(), number(), number(), number(), number()) :: any
  def update_todays_price(currency_name, price, volume, marketcap, ranking) do
    query = from p in HistoricPrice,
      join: c in Currency, on: c.id == p.currency_id,
      where: c.currency_name == ^currency_name and p.date == ^Date.utc_today(),
      order_by: [desc: p.date],
      limit: 1

    case Repo.all(query) do
      [] ->
        {:ok, %Currency{} = currency} = CurrencyRepository.insert_currency(currency_name)
        HistoricPrice.changeset(%HistoricPrice{currency_id: currency.id})
      [changeset] -> changeset
    end
    |> HistoricPrice.changeset(%{price: price, volume: volume, marketcap: marketcap, date: Date.utc_today(), ranking: ranking})
    |> Repo.insert_or_update()
  end

  def add_update_historic_price(%HistoricPrice{} = historic_price) do
    case Repo.one from p in HistoricPrice, where: [currency_id: ^historic_price.currency_id, date: ^historic_price.date], limit: 1 do
      %HistoricPrice{} = p ->
        HistoricPrice.changeset(p, Map.from_struct(historic_price))
      nil ->
        HistoricPrice.changeset(%HistoricPrice{}, Map.from_struct(historic_price))
    end
    |> Repo.insert_or_update()
  end
end
