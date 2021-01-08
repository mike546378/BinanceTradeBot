defmodule CmcscraperWeb.Api.PortfolioController do
  use CmcscraperWeb, :controller
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.Schemas.Currency
  alias Cmcscraper.RepoFunctions.PortfolioRepository

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
end
