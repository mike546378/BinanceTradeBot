defmodule CmcscraperWeb.Api.PortfolioController do
  use CmcscraperWeb, :controller
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.Schemas.Currency
  alias Cmcscraper.Schemas.Portfolio
  alias Cmcscraper.RepoFunctions.PortfolioRepository
  alias Cmcscraper.Helpers.BinanceApiHelper
  alias Cmcscraper.Helpers.PortfolioHelper

  def add(conn, %{"symbol" => symbol, "price" => price, "volume" => volume, "percent" => percent}) do
    %Currency{} = currency = CurrencyRepository.get_currency_by_symbol(symbol)
    PortfolioRepository.insert_trade(currency.id, String.to_float(volume), String.to_float(price), String.to_float(percent))
    json(conn, %{success: true})
  end

  def remove(conn, %{"symbol" => symbol}) do
    %Currency{} = currency = CurrencyRepository.get_currency_by_symbol(symbol)
    PortfolioRepository.remove_trade(currency.id)
    json(conn, %{success: true})
  end

  def list(conn, _params) do
    result = PortfolioRepository.get_active_trades()
    |> Enum.map(fn x ->
      selling_price = Decimal.to_float(x.peak_price) - (Decimal.to_float(x.peak_price)/100*Decimal.to_float(x.percentage_change_requirement))
      Portfolio.to_dto(x)
      |> Map.put(:sellingAt, selling_price) end)
    json(conn, %{success: true, data: result})
  end

  def sync(conn, _params) do
    portfolio = PortfolioRepository.get_active_trades()
    ticker_prices = BinanceApiHelper.get_ticker_prices()
    balances = BinanceApiHelper.get_account_balances()
    |> Enum.map(fn x ->
      %{"asset" => slug, "free" => strBalance} = x
      balance = String.to_float(strBalance)
      ticker_data =  Enum.find(ticker_prices, fn x -> x["symbol"] == slug <> "USDT" end)
      portfolio_record = Enum.find(portfolio, fn y -> y.currency.symbol == slug end)
      currency = CurrencyRepository.get_currency_by_symbol(slug)

      PortfolioHelper.sync_binance(slug, balance, ticker_data, portfolio_record, currency)
    end)
    |> Enum.filter(fn x -> x != nil end)
    |> IO.inspect()
    json(conn, %{success: true, data: balances})
  end

  def updatepercentage(conn, %{"portfolio_id" => p_portfolio_id, "percentage" => p_percentage}) do
    {portfolio_id, _} = Integer.parse(p_portfolio_id)
    {percentage, _} = Integer.parse(p_percentage)

    %Portfolio{} = portfolio = PortfolioRepository.get_by_id(portfolio_id)
    PortfolioRepository.add_update_portfolio(%Portfolio{portfolio | percentage_change_requirement: percentage })
    json(conn, %{success: true, data: Portfolio.to_dto(portfolio)})
  end
end
