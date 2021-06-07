defmodule Cmcscraper.Helpers.AlgoTradingHelper do
  alias Cmcscraper.Models.AlgoTrading.Strategy
  alias Cmcscraper.Models.AlgoTrading.Epoch
  alias Cmcscraper.Models.AlgoTrading.ActiveTrade
  alias Cmcscraper.RepoFunctions.TickerPriceRepository

  # CMC Slope Analysis
  def generate_strategy() do
    tickers =
      TickerPriceRepository.get_tickers_in_range(24, 12)
      |> Enum.group_by(fn x -> x.symbol end, fn y -> y end)

    strategies =
      Enum.map(1..1000, fn _x ->
        %Strategy{
          sell_low: :rand.uniform() * 20,
          sell_high: :rand.uniform() * 20,
          percent_change: :rand.uniform() * 20,
          ticks_count: :rand.uniform(30)
        }
      end)

    threads = 28
    pid = self()
    pids = Enum.map(1..threads, fn _x -> spawn(fn -> epoch_worker_entry(pid, nil, nil) end) end)

    Enum.each(pids, fn p ->
      send(p, {:tickers, tickers})
    end)

    Enum.each(0..(threads - 1), fn x ->
      Enum.at(pids, x)
      |> send(
        {:strategies,
         Enum.slice(
           strategies,
           x * ceil(length(strategies) / threads),
           ceil(length(strategies) / threads)
         )}
      )
    end)

    collect_epochs([], 1000)
    |> mutate_epochs()
    |> run_genetics(threads, pids, 20)
  end

  defp run_genetics(strategies, threads, pids, epoch_counter) when epoch_counter > 0 do
    IO.inspect("Epochs remaining: ")
    IO.inspect(epoch_counter)

    Enum.each(0..(threads - 1), fn x ->
      Enum.at(pids, x)
      |> send(
        {:strategies,
         Enum.slice(
           strategies,
           x * ceil(length(strategies) / threads),
           ceil(length(strategies) / threads)
         )}
      )
    end)

    collect_epochs([], 200)
    |> mutate_epochs()
    |> run_genetics(threads, pids, epoch_counter - 1)
  end

  defp run_genetics(strategies, threads, pids, _epoch_counter) do
    IO.inspect("Final Epoch")

    Enum.each(0..(threads - 1), fn x ->
      Enum.at(pids, x)
      |> send(
        {:strategies,
         Enum.slice(
           strategies,
           x * ceil(length(strategies) / threads),
           ceil(length(strategies) / threads)
         )}
      )
    end)

    top_epoch =
      collect_epochs([], 200)
      |> Enum.sort()
      |> Enum.reverse()
      |> Enum.slice(0, 10)
      |> IO.inspect()
      |> Enum.at(0)

    validation_tickers =
      TickerPriceRepository.get_tickers_in_range(12, 12)
      |> Enum.group_by(fn x -> x.symbol end, fn y -> y end)

    try_strategy_outer(validation_tickers, top_epoch.strategy)
    |> IO.inspect()
  end

  defp mutate_epochs(epochs) do
    epochs
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.slice(0, 10)
    |> IO.inspect()
    |> Enum.map(fn x -> get_mutated_strategies(x.strategy) end)
    |> Enum.flat_map(fn x -> x end)
  end

  defp get_mutated_strategies(strategy = %Strategy{}) do
    IO.inspect("mutating")

    strategies =
      Enum.map(1..19, fn _ ->
        %{
          strategy
          | percent_change: strategy.percent_change * (1.0 + (:rand.uniform() - 0.5) * 0.5),
            sell_high: strategy.sell_high * (1.0 + (:rand.uniform() - 0.5) * 0.5),
            sell_low: strategy.sell_low * (1.0 + (:rand.uniform() - 0.5) * 0.5),
            ticks_count:
              cond do
                strategy.ticks_count <= 2 ->
                  :rand.uniform(9) + 1

                true ->
                  strategy.ticks_count + :rand.uniform(ceil(strategy.ticks_count * 1.25)) -
                    (ceil(strategy.ticks_count * 1.25 / 2) - 1)
              end
        }
      end)

    [strategy | strategies]
  end

  defp collect_epochs(accum, target) when length(accum) < target do
    receive do
      {:epochs, value} ->
        collect_epochs(Enum.concat(accum, value), target)
    end
  end

  defp collect_epochs(accum, _target), do: accum

  def epoch_worker_entry(parent, tickers, strategies = nil) do
    receive do
      {:tickers, value} ->
        tickers = value
        epoch_worker_entry(parent, tickers, strategies)

      {:strategies, value} ->
        strategies = value
        send(parent, {:epochs, epoch_worker(tickers, strategies, [])})
        epoch_worker_entry(parent, tickers, nil)

      {:eos} ->
        :eos
    end
  end

  defp epoch_worker(tickers, [sh = %Strategy{} | st], epochs) do
    epoch = try_strategy_outer(tickers, sh)
    epoch_worker(tickers, st, [epoch | epochs])
  end

  defp epoch_worker(_tickers, [] = _strategies, epochs) do
    epochs
  end

  defp try_strategy_outer(grouped_tickers, %Strategy{} = strategy) do
    epoch = %Epoch{strategy: strategy}
    try_strategy_outer(Map.keys(grouped_tickers), grouped_tickers, epoch)
  end

  defp try_strategy_outer([h | t] = _keys, grouped_tickers, epoch = %Epoch{}) do

    {profit, trades, trades_high, trades_low, total_profit, total_loss, sell_high_ticks,
     sell_low_ticks} =
      try_strategy(grouped_tickers[h], 0, epoch.strategy, {0, 0, 0, 0, 0, 0, 0, 0}, nil)

    try_strategy_outer(t, grouped_tickers, %{
      epoch
      | profit: epoch.profit + profit,
        trades: epoch.trades + trades,
        trades_high: epoch.trades_high + trades_high,
        trades_low: epoch.trades_low + trades_low,
        total_profit: epoch.total_profit + total_profit,
        total_loss: epoch.total_loss + total_loss,
        sell_high_ticks: epoch.sell_high_ticks + sell_high_ticks,
        sell_low_ticks: epoch.sell_low_ticks + sell_low_ticks
    })
  end

  defp try_strategy_outer([] = _keys, _rouped_tickers, epoch = %Epoch{}) do
    cond do
      epoch.trades > 0 ->
        %Epoch{epoch | sell_high_ticks: epoch.sell_high_ticks / epoch.trades, sell_low_ticks: epoch.sell_low_ticks / epoch.trades, profit_per_trade: epoch.profit / epoch.trades }
      true ->
        epoch
      end
  end

  defp try_strategy(
         coin_tickers,
         index,
         %Strategy{} = strategy,
         {profit, trades, trades_high, trades_low, total_profit, total_loss, sell_high_ticks,
          sell_low_ticks} = accum,
         active_trade
       ) do
    cond do
      index > length(coin_tickers) - 1 ->
        accum

      index - strategy.ticks_count < 0 ->
        try_strategy(coin_tickers, index + 1, strategy, accum, active_trade)

      true ->
        target_price =
          (Enum.slice(coin_tickers, index - strategy.ticks_count, strategy.ticks_count)
           |> Enum.map(fn x -> x.price end)
           |> Enum.sum()) / strategy.ticks_count

        current = Enum.at(coin_tickers, index)

        if is_nil(active_trade) do
          if current.price / target_price > strategy.percent_change do
            try_strategy(coin_tickers, index + 1, strategy, accum, %ActiveTrade{
              symbol: current.symbol,
              purchase_price: current.price,
              volume: 500.0 / current.price,
              purchase_tick: index
            })
          else
            try_strategy(coin_tickers, index + 1, strategy, accum, active_trade)
          end
        else
          cond do
            current.price / active_trade.purchase_price > strategy.sell_high ->
              trade_profit = (current.price - active_trade.purchase_price) * active_trade.volume

              trade_profit =
                trade_profit - active_trade.purchase_price * active_trade.volume * 0.00075 -
                  current.price * active_trade.volume * 0.00075

              try_strategy(
                coin_tickers,
                index + 1,
                strategy,
                {
                  profit + trade_profit,
                  trades + 1,
                  trades_high + 1,
                  trades_low,
                  total_profit + trade_profit,
                  total_loss,
                  sell_high_ticks + (index - active_trade.purchase_tick),
                  sell_low_ticks
                },
                nil
              )

            active_trade.purchase_price / current.price > strategy.sell_low ->
              trade_profit = (current.price - active_trade.purchase_price) * active_trade.volume

              trade_profit =
                trade_profit - active_trade.purchase_price * active_trade.volume * 0.00075 -
                  current.price * active_trade.volume * 0.00075

              try_strategy(
                coin_tickers,
                index + 1,
                strategy,
                {
                  profit + trade_profit,
                  trades + 1,
                  trades_high,
                  trades_low + 1,
                  total_profit,
                  total_loss + trade_profit,
                  sell_high_ticks,
                  sell_low_ticks + (index - active_trade.purchase_tick)
                },
                nil
              )

            true ->
              try_strategy(coin_tickers, index + 1, strategy, accum, active_trade)
          end
        end
    end
  end
end
