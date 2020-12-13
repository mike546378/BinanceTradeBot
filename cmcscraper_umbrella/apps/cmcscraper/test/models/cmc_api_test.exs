defmodule Cmcscraper.Models.CmcApiTest do
  use ExUnit.Case, async: true
  alias Cmcscraper.Models.CmcApi

  test "exconstructor ListingLatest" do
    data = %{
      "data" => [
        %{
          "circulating_supply" => 18_569_206,
          "cmc_rank" => 1,
          "date_added" => "2013-04-28T00:00:00.000Z",
          "id" => 1,
          "last_updated" => "2020-12-12T21:51:04.000Z",
          "max_supply" => 21_000_000,
          "name" => "Bitcoin",
          "num_market_pairs" => 9636,
          "platform" => nil,
          "quote" => %{
            "USD" => %{
              "last_updated" => "2020-12-12T21:51:04.000Z",
              "market_cap" => 348_444_159_606.34644,
              "percent_change_1h" => -0.00877099,
              "percent_change_24h" => 4.44658472,
              "percent_change_7d" => -1.69377227,
              "price" => 18764.62351736237,
              "volume_24h" => 21_595_060_029.351135
            }
          },
          "slug" => "bitcoin",
          "symbol" => "BTC",
          "tags" => ["mineable", "pow", "sha-256", "store-of-value", "state-channels"],
          "total_supply" => 18_569_206
        },
        %{
          "circulating_supply" => 113_805_904.874,
          "cmc_rank" => 2,
          "date_added" => "2015-08-07T00:00:00.000Z",
          "id" => 1027,
          "last_updated" => "2020-12-12T21:51:02.000Z",
          "max_supply" => nil,
          "name" => "Ethereum",
          "num_market_pairs" => 5891,
          "platform" => nil,
          "quote" => %{
            "USD" => %{
              "last_updated" => "2020-12-12T21:51:02.000Z",
              "market_cap" => 64_850_230_008.49372,
              "percent_change_1h" => 0.64079334,
              "percent_change_24h" => 4.26955742,
              "percent_change_7d" => -3.93394785,
              "price" => 569.831856091233,
              "volume_24h" => 8_478_712_375.803896
            }
          },
          "slug" => "ethereum",
          "symbol" => "ETH",
          "tags" => ["mineable", "pow", "smart-contracts"],
          "total_supply" => 113_805_904.874
        },
        %{
          "circulating_supply" => 66_072_835.88861056,
          "cmc_rank" => 5,
          "date_added" => "2013-04-28T00:00:00.000Z",
          "id" => 2,
          "last_updated" => "2020-12-12T21:52:02.000Z",
          "max_supply" => 84_000_000,
          "name" => "Litecoin",
          "num_market_pairs" => 745,
          "platform" => nil,
          "quote" => %{
            "USD" => %{
              "last_updated" => "2020-12-12T21:52:02.000Z",
              "market_cap" => 5_085_102_398.798739,
              "percent_change_1h" => 0.57200516,
              "percent_change_24h" => 7.13763833,
              "percent_change_7d" => -7.08532834,
              "price" => 76.96207269461692,
              "volume_24h" => 2_909_838_422.179092
            }
          },
          "slug" => "litecoin",
          "symbol" => "LTC",
          "tags" => ["mineable", "pow", "scrypt", "medium-of-exchange", "binance-chain"],
          "total_supply" => 66_072_835.88861056
        }
      ],
      "status" => %{
        "credit_count" => 1,
        "elapsed" => 13,
        "error_code" => 0,
        "error_message" => nil,
        "notice" => nil,
        "timestamp" => "2020-12-12T21:52:42.521Z",
        "total_count" => 3992
      }
    }

    parsed_data = CmcApi.ListingLatest.from_dto(data)

    assert %CmcApi.ListingLatest{} = parsed_data
    assert is_list(parsed_data.data)

    coin_list = parsed_data.data

    assert 3 = length(coin_list)
    assert %CmcApi.CmcCoin{} = List.first(coin_list)
  end
end
