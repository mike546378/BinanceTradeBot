defmodule Cmcscraper.Helpers.PriceAnalysisHelperTest do
  use ExUnit.Case, async: true
  import Cmcscraper.Helpers.PriceAnalysisHelper
  alias Cmcscraper.Models.CmcApi

  @price_data [
     %Cmcscraper.Schemas.HistoricPrice{
       currency_id: 7,
         currency: %Cmcscraper.Schemas.Currency{
         cmc_id: 2,
         currency_name: "ethereum",
         id: 7,
         inserted_at: ~N[2021-01-06 06:55:16],
         updated_at: ~N[2021-01-06 06:55:16]
       },
       date: ~D[2021-01-06],
       id: 15,
       inserted_at: ~N[2021-01-06 05:55:26],
       marketcap: 5085102398.798739,
       price: 54.63,
       ranking: 20,
       updated_at: ~N[2021-01-06 05:55:26],
       volume: 2909838422.179092
     },
     %Cmcscraper.Schemas.HistoricPrice{
       currency_id: 7,
         currency: %Cmcscraper.Schemas.Currency{
         cmc_id: 2,
         currency_name: "ethereum",
         id: 7,
         inserted_at: ~N[2021-01-06 06:55:16],
         updated_at: ~N[2021-01-06 06:55:16]
       },
       date: ~D[2021-01-05],
       id: 16,
       inserted_at: ~N[2021-01-06 05:55:26],
       marketcap: 5085102398.798739,
       price: 54.63,
       ranking: 19,
       updated_at: ~N[2021-01-06 05:55:26],
       volume: 2909838422.179092
     },
     %Cmcscraper.Schemas.HistoricPrice{
       currency_id: 7,
         currency: %Cmcscraper.Schemas.Currency{
         cmc_id: 2,
         currency_name: "ethereum",
         id: 7,
         inserted_at: ~N[2021-01-06 06:55:16],
         updated_at: ~N[2021-01-06 06:55:16]
       },
       date: ~D[2021-01-04],
       id: 17,
       inserted_at: ~N[2021-01-06 05:55:26],
       marketcap: 5085102398.798739,
       price: 54.63,
       ranking: 17,
       updated_at: ~N[2021-01-06 05:55:26],
       volume: 2909838422.179092
     }
   ]

  test "rank_slope_analysis/1" do
    assert %{end: 17, name: "ethereum", slope: -1.5, start: 20} = rank_slope_analysis(@price_data)
  end

end
