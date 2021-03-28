defmodule CmcscraperWeb.Api.PortfolioController do
  use CmcscraperWeb, :controller
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.Schemas.Currency
  alias Cmcscraper.Schemas.Portfolio
  alias Cmcscraper.RepoFunctions.PortfolioRepository
  alias Cmcscraper.Helpers.BinanceApiHelper

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
      %{portfolio: Portfolio.to_dto(x), selling_at: selling_price} end)
    json(conn, %{success: true, data: result})
  end

  def sync(conn, _params) do
    portfolio = PortfolioRepository.get_active_trades()
    ticker_prices = BinanceApiHelper.get_ticker_prices()
    balances = BinanceApiHelper.get_account_balances()
    |> Enum.map(fn x ->
      %{"asset" => slug, "free" => balance} = x
      case Enum.find(portfolio, fn y -> y.currency.symbol == slug end) do
        nil ->
          if String.to_float(balance) > 0 do
            case CurrencyRepository.get_currency_by_symbol(slug) do
              nil -> %{error: :currency_slug_not_found, slug: slug}
              %Currency{} = currency ->
                case Enum.find(ticker_prices, fn x -> x["symbol"] == slug <> "USDT" end) do
                  nil -> %{error: :trade_pair_not_found, slug: slug}
                  ticker_data ->
                    current_price = String.to_float(ticker_data["price"])
                    IO.inspect(balance)
                    {:ok, resp} = PortfolioRepository.insert_trade(currency.id, balance, current_price)
                    Portfolio.to_dto(resp)
                end
              _ -> {:error, slug}
            end
          end
        %Portfolio{} = pfolio ->
          if pfolio.volume != balance do
            {:ok, resp}  = PortfolioRepository.add_update_portfolio(%Portfolio{pfolio | volume: balance})
            Portfolio.to_dto(resp)
          end
      end
    end)
    json(conn, %{success: true, data: balances})
  end
end
