defmodule Cmcscraper.Helpers.AlgoTradingHelper do
  alias Cmcscraper.Models.AlgoTrading.Strategy
  alias Cmcscraper.Models.AlgoTrading.Epoch
  alias Cmcscraper.Models.AlgoTrading.ActiveTrade
  alias Cmcscraper.RepoFunctions.TickerPriceRepository
  alias Cmcscraper.RepoFunctions.AlgoRepository

  # CMC Slope Analysis
  def generate_strategy() do
    tickers =
#      TickerPriceRepository.get_tickers_in_range(5, 2)
      TickerPriceRepository.get_last_n_tickers(160)
      #TickerPriceRepository.get_last_n_tickers(320)

    strategies =
      Enum.map(1..3000, fn _x ->
        %Strategy{
          sell_low: :rand.uniform() * 10,
          sell_high: :rand.uniform() * 10,
          percent_change: :rand.uniform() * 10,
          ticks_count: :rand.uniform(30)
        }
      end)

    threads = 21
    runs = 70

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

    epochs = collect_epochs([], 3000)

    sorted = Enum.sort(epochs, &(Epoch.compare(&1, &2) != :gt))
    |> Enum.reverse()
    IO.inspect(Enum.at(sorted, 0))
    IO.inspect(Enum.at(sorted, Kernel.length(sorted) - 1))

    %Epoch{} = top_epoch = mutate_epochs(epochs)
    |> run_genetics(threads, pids, runs)

    AlgoRepository.add_strategy(top_epoch.strategy)
    #validate_strategy(top_epoch.strategy)
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

    collect_epochs([], 400)
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

    collect_epochs([], 400)
    |> Enum.sort(&(Epoch.compare(&1, &2) != :gt))
    |> Enum.reverse()
    |> Enum.slice(0, 10)
    |> IO.inspect()
    |> Enum.at(0)
  end

  def validate_strategy(strategy) do
    validation_tickers =
      TickerPriceRepository.get_tickers_in_range(3, 1)
      |> Enum.group_by(fn x -> x.datetime end, fn y -> y end)
      |> Map.to_list()
      |> Enum.map(fn {date, prices} ->
        {date,
         Enum.reduce(prices, %{}, fn ticker, accum ->
           Map.put(accum, ticker.symbol, ticker.price)
         end)}
      end)

    try_strategy_outer(validation_tickers, strategy)
    |> IO.inspect()
  end

  defp mutate_epochs(epochs) do
    sorted_epochs =
      Enum.sort(epochs, &(Epoch.compare(&1, &2) != :gt))
      |> Enum.reverse()

    sorted_epochs
    |> Enum.at(0)
    |> IO.inspect()

    sorted_epochs
    |> Enum.slice(0, 10)
    |> Enum.map(fn x -> get_mutated_strategies(x.strategy) end)
    |> Enum.flat_map(fn x -> x end)
  end

  defp get_mutated_strategies(strategy = %Strategy{}) do
    strategies =
      Enum.map(1..39, fn _ ->
        %{
          strategy
          | percent_change: mutate_float(strategy.percent_change, 10),
            sell_high: mutate_float(strategy.sell_high, 8),
            sell_low: mutate_float(strategy.sell_low, 8),
            ticks_count: mutate_tick_counter(strategy.ticks_count, 10)
        }
      end)

    [strategy | strategies]
  end

  defp mutate_float(start, max_val) do
    r = :rand.uniform()

    cond do
      r > 0.5 -> start
      r > 0.25 -> start * (1.0 + (:rand.uniform() - 0.5) * 0.5)
      true -> :rand.uniform() * max_val
    end
  end

  defp mutate_tick_counter(start, max_val) do
    r = :rand.uniform()

    cond do
      r > 0.5 ->
        start

      r > 0.25 ->
        if start <= 2 do
          :rand.uniform(max_val - 1) + 1
        else
          start + :rand.uniform(ceil(start * 1.25)) - (ceil(start * 1.25 / 2) - 1)
        end

      true ->
        :rand.uniform(max_val - 1) + 1
    end
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
    new_epoch = %Epoch{} = try_strategy(grouped_tickers, 0, epoch, %{}, 5000)

    %Epoch{
      new_epoch
      | profit_per_trade:
          if new_epoch.trades > 0 do
            new_epoch.profit / new_epoch.trades
          else
            0
          end,
        sell_high_ticks:
          if new_epoch.trades_high > 0 do
            new_epoch.sell_high_ticks / new_epoch.trades_high
          else
            0
          end,
        sell_low_ticks:
          if new_epoch.trades_low > 0 do
            new_epoch.sell_low_ticks / new_epoch.trades_low
          else
            0
          end,
        trades_per_tick: new_epoch.trades / length(grouped_tickers),
        risk: Epoch.calculate_risk(new_epoch)
    }
  end

  defp try_strategy(
         coin_tickers,
         index,
         %Epoch{} = epoch,
         active_trades,
         available_balance
       )
       when is_map(active_trades) do
    cond do
      index > length(coin_tickers) - 1 ->
        epoch

      index - epoch.strategy.ticks_count < 0 ->
        try_strategy(coin_tickers, index + 1, epoch, active_trades, available_balance)

      true ->
        {_datetime, tickers} = Enum.at(coin_tickers, index)

        {epoch, active_trades, available_balance} =
          try_buy_sell(
            coin_tickers,
            index,
            Map.keys(tickers),
            epoch,
            active_trades,
            available_balance
          )

        try_strategy(coin_tickers, index + 1, epoch, active_trades, available_balance)
    end
  end

  def try_buy_sell(
        all_tickers,
        index,
        [symbol | remaining_symbols] = _keys,
        epoch = %Epoch{},
        active_trades,
        available_balance
      )
      when is_map(active_trades) do
    {_datetime, current_ticker} = Enum.at(all_tickers, index)

    if Map.has_key?(active_trades, symbol) do
      #### Check sell
      current_price = current_ticker[symbol]

      trade_profit =
        (current_price - active_trades[symbol].purchase_price) * active_trades[symbol].volume

      fees =
        active_trades[symbol].purchase_price * active_trades[symbol].volume * 0.00075 +
          current_price * active_trades[symbol].volume * 0.00075

      trade_profit = trade_profit - fees

      cond do
        (current_price / active_trades[symbol].purchase_price - 1) * 100 >
            epoch.strategy.sell_high ->
          if epoch.risk > 0.3 and epoch.profit > 100 and epoch.strategy.sell_high < 0.075 do
            IO.inspect("Profit: " <> to_string(trade_profit) <> "  Fees: " <> to_string(fees))
          end
          try_buy_sell(
            all_tickers,
            index,
            remaining_symbols,
            %Epoch{
              epoch
              | profit: epoch.profit + trade_profit,
                trades: epoch.trades + 1,
                trades_high: epoch.trades_high + 1,
                total_profit: epoch.total_profit + trade_profit,
                sell_high_ticks:
                  epoch.sell_high_ticks + (index - active_trades[symbol].purchase_tick)
            },
            Map.delete(active_trades, symbol),
            available_balance +
              active_trades[symbol].purchase_price * active_trades[symbol].volume +
              trade_profit
          )

        (active_trades[symbol].purchase_price / current_price - 1) * 100 > epoch.strategy.sell_low ->
          try_buy_sell(
            all_tickers,
            index,
            remaining_symbols,
            %Epoch{
              epoch
              | profit: epoch.profit + trade_profit,
                trades: epoch.trades + 1,
                trades_low: epoch.trades_low + 1,
                total_loss: epoch.total_loss + trade_profit,
                sell_low_ticks:
                  epoch.sell_low_ticks + (index - active_trades[symbol].purchase_tick)
            },
            Map.delete(active_trades, symbol),
            available_balance +
              active_trades[symbol].purchase_price * active_trades[symbol].volume + trade_profit
          )

        true ->
          try_buy_sell(
            all_tickers,
            index,
            remaining_symbols,
            epoch,
            active_trades,
            available_balance
          )
      end
    else
      ### Should Buy ?
      current_price = current_ticker[symbol]

      average_price =
        Enum.slice(
          all_tickers,
          index - epoch.strategy.ticks_count,
          epoch.strategy.ticks_count
        )
        |> Enum.reduce(0, fn {_datetime, tickers}, accum ->
          accum +
            if Map.has_key?(tickers, symbol) do
              tickers[symbol]
            else
              0
            end
        end)

      average_price = average_price / epoch.strategy.ticks_count

      cond do
        average_price == 0 ->
          try_buy_sell(
            all_tickers,
            index,
            remaining_symbols,
            epoch,
            active_trades,
            available_balance
          )

        current_price / average_price > epoch.strategy.percent_change && available_balance >= 500 ->
          ## Do buy
          try_buy_sell(
            all_tickers,
            index,
            remaining_symbols,
            epoch,
            Map.put(active_trades, symbol, %ActiveTrade{
              symbol: symbol,
              purchase_price: current_price,
              volume: 500.0 / current_price,
              purchase_tick: index
            }),
            available_balance - 500
          )

        true ->
          ## Don't buy
          try_buy_sell(
            all_tickers,
            index,
            remaining_symbols,
            epoch,
            active_trades,
            available_balance
          )
      end
    end
  end

  def try_buy_sell(
        _,
        _,
        [],
        epoch = %Epoch{},
        active_trades,
        available_balance
      ) do
    {epoch, active_trades, available_balance}
  end
end
