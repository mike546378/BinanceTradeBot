defmodule CmcscraperWeb.Api.DataController do
  use CmcscraperWeb, :controller
  alias Cmcscraper.Genservers.UpdateServer
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.RepoFunctions.HistoricPriceRepository
  alias Cmcscraper.Helpers.PriceAnalysisHelper

  def update_latest_prices(conn, _params) do
      UpdateServer.update_latest_prices()
      json(conn, %{success: true})
  end

  def get_coin_by_name(conn, %{"name" => name}) do
    currency = CurrencyRepository.to_dto(CurrencyRepository.get_currency_by_name(name))
    json(conn, currency)
  end

  def get_currency_data(conn, %{"limit" => limit, "offset" => offset}) do

    {offset, _} = Integer.parse(offset)
    {limit, _} = Integer.parse(limit)

    currency = Enum.map(CurrencyRepository.get_currency_data(limit, offset), fn x -> CurrencyRepository.to_dto(x) end)
    json(conn, currency)
  end

  def get_currency_data(conn, %{}) do
    get_currency_data(conn, %{"limit" => 100, "offset" => 0})
  end

  def get_currency_data(conn, %{"limit" => limit, "offset" => offset}) do

    {offset, _} = Integer.parse(offset)
    {limit, _} = Integer.parse(limit)

    currency = Enum.map(CurrencyRepository.get_currency_data(limit, offset), fn x -> CurrencyRepository.to_dto(x) end)
    json(conn, currency)
  end

  def get_analysis(conn, _params) do
    data = HistoricPriceRepository.get_recent_price_data_grouped(4)
    currency = Enum.map(data,
    fn record ->
      {_id, price_history} = record
      PriceAnalysisHelper.rank_slope_analysis(price_history)
    end)
    |> IO.inspect()
    |> Enum.sort_by(&{&1.slope})
    json(conn, currency)
  end
end
