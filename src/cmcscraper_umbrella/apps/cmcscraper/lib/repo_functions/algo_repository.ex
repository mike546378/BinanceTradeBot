defmodule Cmcscraper.RepoFunctions.AlgoRepository do
  import Ecto.Query
  alias Cmcscraper.Repo
  alias Cmcscraper.Schemas.AlgoStrategy
  alias Cmcscraper.Schemas.AlgoTrade
  alias Cmcscraper.Models.BinanceApi.TradeOrder
  alias Cmcscraper.Models.AlgoTrading

  def get_open_trades() do
    from(t in AlgoTrade,
      join: s in AlgoStrategy,
      on: s.id == t.algo_strategy_id,
      where: is_nil(t.sell_date),
      preload: [algo_strategy: s]
    )
    |> Repo.all()
  end

  def get_current_strategy() do
    from(s in AlgoStrategy,
      where: s.is_active == true
    )
    |> Repo.one()
  end

  def add_strategy(%AlgoTrading.Strategy{} = strategy) do
    AlgoStrategy.changeset(
      %AlgoStrategy{},
      Map.from_struct(%AlgoStrategy{
        sell_low: strategy.sell_low,
        sell_high: strategy.sell_high,
        ticks_count: strategy.ticks_count,
        percentage_change: strategy.percent_change,
        purchase_size: Application.get_env(:cmcscraper, :algo_batch_size),
        profit: 0,
        is_active: false,
      })
    )
    |> Repo.insert!()
  end

  def sell_trade(
        %{"status" => "FILLED", "side" => "SELL"} = resp,
        existing_trade = %AlgoTrade{},
        strategy = %AlgoStrategy{},
        tickers
      )
      when is_map(tickers) do
    %TradeOrder{} = order = TradeOrder.from_dto(resp)
    fees_usdt = TradeOrder.calc_fees(order, tickers)
    IO.inspect("fees: " <> Decimal.to_string(fees_usdt))
    avg_price = Decimal.div(order.cummulative_quote_qty, order.executed_qty)

    Repo.get_by(AlgoTrade, [id: existing_trade.id])
    |> AlgoTrade.changeset(%{
      sell_price: avg_price,
      sell_date: DateTime.utc_now(),
      sell_fee_usdt: fees_usdt
    })
    |> Repo.insert_or_update!()

    Repo.get_by(AlgoStrategy, [id: existing_trade.algo_strategy_id])
    |> AlgoStrategy.changeset(%{
      profit:
        Decimal.sub(avg_price, existing_trade.purchase_price)
        |> Decimal.mult(order.executed_qty)
        |> Decimal.add(strategy.profit)
    })
    |> Repo.insert_or_update!()
  end

  def sell_trade(resp, _, _, _) do
    IO.inspect("Unexpected response sell_trade/4: ")
    IO.inspect(resp)
  end

  def add_trade(%{"status" => "FILLED", "side" => "BUY"} = resp, strategy_id, tickers)
      when is_map(tickers) and is_integer(strategy_id) do
    %TradeOrder{} = order = TradeOrder.from_dto(resp)
    fees_usdt = TradeOrder.calc_fees(order, tickers)
    IO.inspect("fees: " <> Decimal.to_string(fees_usdt))
    avg_price = Decimal.div(order.cummulative_quote_qty, order.executed_qty)

    AlgoTrade.changeset(
      %AlgoTrade{},
      Map.from_struct(%AlgoTrade{
        purchase_date: DateTime.utc_now(),
        purchase_price: avg_price,
        symbol: order.symbol,
        volume: order.executed_qty,
        algo_strategy_id: strategy_id,
        buy_fee_usdt: fees_usdt
      })
    )
    |> Repo.insert!()
  end

  def add_trade(resp, _strategy_id, _tickers) do
    IO.inspect("Unexpected response add_trade/3: ")
    IO.inspect(resp)
  end
end
