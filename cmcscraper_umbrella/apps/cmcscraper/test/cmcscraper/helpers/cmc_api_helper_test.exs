defmodule Cmcscraper.Helpers.CmcApiHelperTest do
  use ExUnit.Case, async: true
  import Cmcscraper.Helpers.CmcApiHelper
  alias Cmcscraper.Models.CmcApi

    test "get_request" do
      assert %CmcApi.ListingLatest{} = get_request("v1/cryptocurrency/listings/latest", "limit=5")
    end
  end
