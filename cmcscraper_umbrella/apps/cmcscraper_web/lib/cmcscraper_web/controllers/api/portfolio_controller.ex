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

  def list(conn, _params) do
    PortfolioRepository.get_active_trades()
    |> Enum.map(fn x -> %{x | selling_at: x.peak_price - (x.peak_price/100*x.required_percentage)} end)
    json(conn, %{success: true})
  end
end
