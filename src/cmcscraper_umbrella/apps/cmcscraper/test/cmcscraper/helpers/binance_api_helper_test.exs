defmodule Cmcscraper.Helpers.BinanceApiHelperTest do
  use ExUnit.Case, async: true
  import Cmcscraper.Helpers.BinanceApiHelper
  alias Cmcscraper.Models.CmcApi

  test "get_request" do
    assert %{"mins" => _, "price" => _ } = get_request("v3/avgPrice", "symbol=BTCUSDT")
  end

  test "get_average_price/1" do
    resp = get_average_price("BTC")
    assert is_number(resp)
    assert resp > 500
  end
end
