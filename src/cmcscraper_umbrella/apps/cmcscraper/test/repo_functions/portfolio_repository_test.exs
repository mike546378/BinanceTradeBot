defmodule Cmcscraper.RepoFunctions.PortfolioRepositoryTest do
  use ExUnit.Case, async: true
  import Cmcscraper.RepoFunctions.PortfolioRepository
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.Schemas.Portfolio
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

  @portfolio_item %Portfolio{
    currency_id: 1,
    purchase_date: DateTime.utc_now(),
    purchase_price: 500,
    percentage_change_requirement: 10,
    volume: 0.5,
    peak_price: 520,
  }

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Cmcscraper.Repo)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.checkin(Cmcscraper.Repo) end)
  end

  test "add_update_portfolio/1 creates a new historic_price" do
    {:ok, %Currency{} = currency} = CurrencyRepository.add_update_currency(Currency.from_object(@cmc_coin))
    assert {:ok, %Portfolio{}} = add_update_portfolio(%{ @portfolio_item | currency_id: currency.id })
  end

  test "add_update_portfolio/1 updates an existing historic_price" do
    {:ok, %Currency{} = currency} = CurrencyRepository.add_update_currency(Currency.from_object(@cmc_coin))

    {:ok, price} = Decimal.cast(520)
    {:ok, %Portfolio{peak_price: ^price} = result} = add_update_portfolio(%{ @portfolio_item | currency_id: currency.id })

    portfolio_id = result.id
    {:ok, price} = Decimal.cast(590)
    new_portfolio = %{ @portfolio_item | id: portfolio_id, currency_id: currency.id, peak_price: 590 }
    assert {:ok, %Portfolio{id: ^portfolio_id, peak_price: ^price }} = add_update_portfolio(new_portfolio)
  end

  test "insert_trade/1 inserts a new portfolio item" do
    {:ok, %Currency{} = currency} = CurrencyRepository.add_update_currency(Currency.from_object(@cmc_coin))

    {:ok, price} = Decimal.cast(500)
    {:ok, volume} = Decimal.cast(5)
    assert {:ok, %Portfolio{volume: ^volume, purchase_price: ^price, sell_date: nil}} = insert_trade(currency.id, 5, 500)
  end

  test "sell_trade/1 updates existing portfolio item to sold" do
    {:ok, %Currency{} = currency} = CurrencyRepository.add_update_currency(Currency.from_object(@cmc_coin))

    {:ok, price} = Decimal.cast(500)
    {:ok, volume} = Decimal.cast(5)
    assert {:ok, %Portfolio{id: id, volume: ^volume, purchase_price: ^price }} = insert_trade(currency.id, 5, 500)
    assert {:ok, %Portfolio{id: ^id, volume: ^volume, purchase_price: ^price, sell_date: sell_date}} = sell_trade(id, 900)

    min_time = DateTime.utc_now() |> DateTime.add(-60, :second)
    max_time = DateTime.utc_now() |> DateTime.add(5, :second)
    assert :gt = DateTime.compare(sell_date, min_time)
    assert :lt = DateTime.compare(sell_date, max_time)
  end

  test "get_all_trades/1 retrieves all portfolio items" do
    {:ok, %Currency{} = currency} = CurrencyRepository.add_update_currency(Currency.from_object(@cmc_coin))

    {:ok, %Portfolio{}} = insert_trade(currency.id, 5, 500)
    {:ok, %Portfolio{id: id2}} = insert_trade(currency.id, 10, 600)
    {:ok, %Portfolio{}} = insert_trade(currency.id, 3, 400)

    {:ok, %Portfolio{}} = sell_trade(id2, 900.0)

    assert [%Portfolio{} | _] = result = get_all_trades()
    assert Enum.count(result) == 3
  end


  test "get_active_trades/1 retrieves all active portfolio items" do
    {:ok, %Currency{} = currency} = CurrencyRepository.add_update_currency(Currency.from_object(@cmc_coin))

    {:ok, %Portfolio{}} = insert_trade(currency.id, 5, 500)
    {:ok, %Portfolio{id: id2}} = insert_trade(currency.id, 10, 600)
    {:ok, %Portfolio{}} = insert_trade(currency.id, 3, 400)

    {:ok, %Portfolio{}} = sell_trade(id2, 900.0)

    assert [%Portfolio{} | _] = result = get_active_trades()
    assert Enum.count(result) == 2
  end
end
