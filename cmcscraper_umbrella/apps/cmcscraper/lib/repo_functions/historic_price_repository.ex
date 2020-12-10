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

  @spec update_todays_price(any, any, any, any, any) :: any
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

  def perform_historic_mapping do
    query = from p in HistoricPrice,
      order_by: [desc: p.date, desc: p.marketcap]

    Repo.all(query)
    |> perform_historic_mapping(1)
  end

  def perform_historic_mapping([], _) do
    {:ok}
  end

  def perform_historic_mapping([%{currency_id: 1}|_tail] = list, ranking) when ranking > 1 do
    perform_historic_mapping(list, 1)
  end

  def perform_historic_mapping([changeset|tail], ranking) do

    HistoricPrice.changeset(changeset, %{ranking: ranking})
    |> Repo.insert_or_update()

    perform_historic_mapping(tail, ranking+1)
  end

end
