defmodule Cmcscraper.Helpers.CmcApiHelper do
  alias Cmcscraper.Models.CmcApi

  def get_request(endpoint, query) do
    api_key = Application.get_env(:cmcscraper, :cmc_api_key)
    base_url = Application.get_env(:cmcscraper, :cmc_api_uri)

    response = HTTPoison.get!(base_url <> endpoint <> "?" <> query, [{"X-CMC_PRO_API_KEY", api_key}])
    Poison.decode!(response.body)
  end

  def get_latest_prices(count) do
    get_request("v1/cryptocurrency/listings/latest", "limit=" <> to_string(count))
    |> CmcApi.ListingLatest.from_dto()
  end
end
