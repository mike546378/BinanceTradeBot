defmodule Cmcscraper.Helpers.CmcApiHelper do

  def post_request(endpoint, payload) do
    api_key = Application.get_env(:cmcscraper, :cmc_api_key)
    base_url = Application.get_env(:cmcscraper, :cmc_api_uri)

    response = HTTPoison.get!(base_url + endpoint)
    Poison.decode!(response.body)
  end
  
end
