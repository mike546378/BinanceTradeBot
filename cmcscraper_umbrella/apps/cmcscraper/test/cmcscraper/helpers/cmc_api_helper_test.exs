defmodule Cmcscraper.Helpers.CmcApiHelperTest do
  use ExUnit.Case, async: true
  import Cmcscraper.Helpers.CmcApiHelper
  alias Cmcscraper.Models.CmcApi

    test "get_request" do
      assert %{"data" => _, "status" => _ } = get_request("v1/cryptocurrency/listings/latest", "limit=5")
    end

    test "get_latest_prices/1" do
      assert %CmcApi.ListingLatest{} = get_latest_prices(5)
    end
  end
