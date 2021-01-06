defmodule Cmcscraper.RepoFunctions.HistoricPriceRepository do
  import Ecto.Query
  alias Cmcscraper.Repo
  alias Cmcscraper.Schemas.HistoricPrice
  alias Cmcscraper.Schemas.Currency
  alias DateTime

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

  def get_recent_price_data(days) do

    date = Date.utc_today
      |> Date.add(-(days-1))

    price_query =
      from p in HistoricPrice,
        join: c in Currency,
          on: c.id == p.currency_id,
        where: p.date >= ^date,
        preload: [currency: c]

    Repo.all(price_query)
  end

  def get_recent_price_data_grouped(days) do
    get_recent_price_data(days)
    |> Enum.group_by(fn p -> p.currency_id end, fn p -> p end)
    |> Map.to_list
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
