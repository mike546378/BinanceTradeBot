defmodule Cmcscraper.RepoFunctions.CurrencyRepositoryTest do
  use ExUnit.Case, async: true
  import Cmcscraper.RepoFunctions.CurrencyRepository
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

  test "add_update_currency/1 creates a new currency" do
    assert {:ok, %Currency{}} = add_update_currency(Currency.from_object(@cmc_coin))
  end

  test "add_update_currency/1 updates an existing currency" do
    {:ok, %Currency{cmc_id: 2} = currency} = add_update_currency(Currency.from_object(@cmc_coin))
    currency_id = currency.id
    assert {:ok, %Currency{cmc_id: 5, id: ^currency_id}} = add_update_currency(%{ Currency.from_object(@cmc_coin) | cmc_id: 5 })
  end
end
