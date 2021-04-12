defmodule Cmcscraper.RepoFunctions.HistoricPriceRepositoryTest do
  use ExUnit.Case, async: true
  import Cmcscraper.RepoFunctions.HistoricPriceRepository
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.Schemas.HistoricPrice
  alias Cmcscraper.Schemas.Currency

  @cmc_coin %Cmcscraper.Models.CmcApi.CmcCoin{
    circulating_supply: 66_072_835.88861056,
    cmc_rank: 5,
    date_added: ~N[2013-04-28 00:00:00.000],
    id: 2,
    last_updated: ~N[2020-12-12 21:52:02.000],
    max_supply: 84_000_000,
    name: "Litecoin",
    num_market_pairs: 745,
    platform: nil,
    quote: %Cmcscraper.Models.CmcApi.CmcQuote{
      usd: %Cmcscraper.Models.CmcApi.CmcQuoteDetails{
        last_updated: ~N[2020-12-12 21:52:02.000],
        market_cap: 5_085_102_398.798739,
        percent_change_1h: 0.57200516,
        percent_change_24h: 7.13763833,
        percent_change_7d: -7.08532834,
        price: 546.3,
        volume_24h: 2_909_838_422.179092
      }
    },
    slug: "litecoin",
    symbol: "LTC",
    tags: ["mineable", "pow", "scrypt", "medium-of-exchange", "binance-chain"],
    total_supply: 66_072_835.88861056
  }


    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Cmcscraper.Repo)
      on_exit(fn -> Ecto.Adapters.SQL.Sandbox.checkin(Cmcscraper.Repo) end)
    end

    test "add_update_historic_price/1 creates a new historic_price" do
      {:ok, %Currency{} = currency} = CurrencyRepository.add_update_currency(Currency.from_object(@cmc_coin))
      assert {:ok, %HistoricPrice{}} = add_update_historic_price(%{ HistoricPrice.from_object(@cmc_coin) | currency_id: currency.id })
    end

    test "add_update_historic_price/1 updates an existing historic_price" do
      {:ok, %Currency{} = currency} = CurrencyRepository.add_update_currency(Currency.from_object(@cmc_coin))

      price = Decimal.from_float(546.3)
      {:ok, %HistoricPrice{price: ^price} = result} = add_update_historic_price(%{ HistoricPrice.from_object(@cmc_coin) | currency_id: currency.id })

      price_id = result.id
      price = Decimal.from_float(54.63)
      new_historic_price = %{ HistoricPrice.from_object(@cmc_coin) | currency_id: currency.id, price: 54.63 }
      assert {:ok, %HistoricPrice{id: ^price_id, price: ^price}} = add_update_historic_price(new_historic_price)
    end

    test "get_recent_price_data/1" do
      test_coin = @cmc_coin
      insert_test_price_data(test_coin, 1)
      insert_test_price_data(%{ test_coin | slug: "bitcoin" }, 2)
      insert_test_price_data(%{ test_coin | slug: "ethereum" }, 3)

      assert length(get_recent_price_data(3)) == 9
      assert length(get_recent_price_data(4)) == 12
      assert [ %HistoricPrice{} | _ ] = get_recent_price_data(2)
    end

    test "get_recent_price_data_grouped/1" do
      test_coin = @cmc_coin
      insert_test_price_data(test_coin, 1)
      insert_test_price_data(%{ test_coin | slug: "bitcoin" }, 2)
      insert_test_price_data(%{ test_coin | slug: "ethereum" }, 3)

      result = get_recent_price_data_grouped(3)
      assert length(result) == 3
      [head | _ ] = result
      assert {_id, [%HistoricPrice{} | _]} = head
    end


    defp insert_test_price_data(cmc_coin, initial_rank) do
      {:ok, %Currency{} = currency} = CurrencyRepository.add_update_currency(Currency.from_object(cmc_coin))
      historic_price = %{ HistoricPrice.from_object(cmc_coin) | currency_id: currency.id, price: 54.63, date: DateTime.utc_now |> DateTime.to_naive }
      add_update_historic_price(%{ historic_price | date: Date.utc_today |> Date.add(-0), ranking: initial_rank })
      add_update_historic_price(%{ historic_price | date: Date.utc_today |> Date.add(-1), ranking: initial_rank + 1 })
      add_update_historic_price(%{ historic_price | date: Date.utc_today |> Date.add(-2), ranking: initial_rank + 2 })
      add_update_historic_price(%{ historic_price | date: Date.utc_today |> Date.add(-3), ranking: initial_rank + 3 })
      add_update_historic_price(%{ historic_price | date: Date.utc_today |> Date.add(-4), ranking: initial_rank + 4 })
      add_update_historic_price(%{ historic_price | date: Date.utc_today |> Date.add(-5), ranking: initial_rank + 5 })
      currency
    end
  end
