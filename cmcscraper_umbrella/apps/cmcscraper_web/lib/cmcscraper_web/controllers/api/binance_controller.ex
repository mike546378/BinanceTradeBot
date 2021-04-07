defmodule CmcscraperWeb.Api.BinanceController do
  use CmcscraperWeb, :controller
  alias Cmcscraper.Helpers.BinanceApiHelper

  def get_balance_by_symbol(conn, %{"symbol" => symbol}) do
      resp = BinanceApiHelper.get_account_balance(symbol)
      json(conn, resp)
  end

  def get_balance_full(conn, _) do
    resp = BinanceApiHelper.get_account_balances()
    json(conn, resp)
  end

  def sell_by_symbol(conn, %{"symbol" => symbol}) do
    resp = BinanceApiHelper.sell_all(symbol)
    json(conn, resp)
  end

end
