defmodule Cmcscraper.Genservers.UpdateServerLogic do
  use GenServer

  alias Cmcscraper.RepoFunctions.HistoricPriceRepository
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.RepoFunctions.PortfolioRepository
  alias Cmcscraper.RepoFunctions.TickerPriceRepository
  alias Cmcscraper.RepoFunctions.AlgoRepository
  alias Cmcscraper.Schemas.Currency
  alias Cmcscraper.Schemas.HistoricPrice
  alias Cmcscraper.Schemas.AlgoStrategy
  alias Cmcscraper.Schemas.AlgoTrade
  alias Cmcscraper.Schemas.TickerPrices
  alias Cmcscraper.Schemas.Portfolio
  alias Cmcscraper.Helpers.CmcApiHelper
  alias Cmcscraper.Helpers.BinanceApiHelper
  alias Cmcscraper.Helpers.AlgoTradingHelper
  alias Cmcscraper.Models.CmcApi
  alias Cmcscraper.Models.BinanceApi

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    Process.register(self(), :update_server)
    # send(self(), {:delayed_price_update_loop})
    send(self(), {:strategy_generation_loop})
    send(self(), {:delayed_binance_loop})
    send(self(), {:exchange_info_loop})
    {:ok, state}
  end

  @impl true
  def handle_info({:delayed_price_update_loop}, socket) do
    Process.send_after(self(), {:price_update_loop}, 3 * 60 * 1000)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:price_update_loop}, socket) do
    send(self(), {:op_update_latest_prices})
    Process.send_after(self(), {:price_update_loop}, 30 * 60 * 1000)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:delayed_binance_loop}, socket) do
    Process.send_after(self(), {:binance_loop}, 10 * 1000)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:exchange_info_loop}, socket) do
    Process.send_after(self(), {:exchange_info_loop},  60 * 60 * 1000)
    BinanceApiHelper.store_exchange_info()
    {:noreply, socket}
  end

  @impl true
  def handle_info({:binance_loop}, socket) do
    Process.send_after(self(), {:binance_loop}, 45 * 1000)
    send(self(), {:binance_worker})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:strategy_generation_loop}, socket) do
    Task.start_link(fn -> AlgoTradingHelper.generate_strategy() end)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:op_update_latest_prices}, socket) do
    IO.inspect("Updating latest prices")
    %CmcApi.ListingLatest{} = prices = CmcApiHelper.get_latest_prices(200)

    Enum.each(prices.data, fn c ->
      {:ok, %Currency{} = currency} =
        CurrencyRepository.add_update_currency(Currency.from_object(c))

      HistoricPriceRepository.add_update_historic_price(%{
        HistoricPrice.from_object(c)
        | currency_id: currency.id
      })
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:binance_worker}, socket) do
    IO.inspect("Binance Worker")
    case Application.get_env(:cmcscraper, :worker_mode) do
      "portfolio" ->
        active_trades = PortfolioRepository.get_active_trades()
        ticker_prices = BinanceApiHelper.get_ticker_prices()
        _ticker_datetime = DateTime.utc_now()

        binance_tailing_stop_loss(active_trades, ticker_prices)
        #insert_tickers(ticker_prices, ticker_datetime)

      "algo_trade" ->
        open_trades = AlgoRepository.get_open_trades()
        current_strategy = AlgoRepository.get_current_strategy()

        max_ticks_trade = %AlgoTrade{} =
          Enum.max(
            open_trades,
            fn a, b -> a.algo_strategy.ticks_count >= b.algo_strategy.ticks_count end,
            fn -> %AlgoTrade{algo_strategy: %AlgoStrategy{ticks_count: 0}} end
          )

        max_ticks =
          if current_strategy == nil || max_ticks_trade.algo_strategy.ticks_count > current_strategy.ticks_count do
            max_ticks_trade.algo_strategy.ticks_count
          else
            current_strategy.ticks_count
          end

        recent_ticks = TickerPriceRepository.get_last_n_tickers(max_ticks)
        average_prices = if Kernel.length(recent_ticks) == 0, do: [], else: map_average_price(recent_ticks, max_ticks)

        ticker_prices = BinanceApiHelper.get_ticker_prices()
        |> Enum.filter(fn x -> x["symbol"] =~ "USDT" end)
        |> Enum.reduce(%{}, fn %{"price" => price, "symbol" => symbol}, accum ->
          Map.put(accum, symbol, String.to_float(price))
        end)
         _ticker_datetime = DateTime.utc_now()

        if Kernel.length(recent_ticks) == max_ticks && max_ticks > 0 do
          open_trades = algo_trade_seller(open_trades, average_prices, ticker_prices, [])

          if !is_nil(current_strategy) and Kernel.length(open_trades) < Application.get_env(:cmcscraper, :algo_max_open_trades) and Decimal.compare(current_strategy.profit, Decimal.div(current_strategy.purchase_size, 4) |> Decimal.mult(-1)) == :gt do
            IO.inspect("Try buy")
            ignore = Enum.map(open_trades, fn x -> x.symbol end)
            algo_trade_buyer(current_strategy, ticker_prices, Map.keys(ticker_prices), average_prices, ["BNBUSDT" | ignore])
          end
        end

        #insert_tickers(ticker_prices, ticker_datetime)

      _ ->
        {:ok}
        #BinanceApiHelper.get_ticker_prices()
        #|> insert_tickers()
    end

    {:noreply, socket}
  end

  defp map_average_price(grouped_tickers, count) do
    {_date, latest_ticker} = Enum.at(grouped_tickers, 0)

    averaged_ticker =
      Enum.map(latest_ticker, fn {symbol, _price} ->
        grouped_tickers_slice = Enum.slice(grouped_tickers, 0, count)

        average_symbol_price =
          Enum.reduce(grouped_tickers_slice, 0, fn {_datetime, tickers}, accum ->
            accum +
              if Map.has_key?(tickers, symbol) do
                tickers[symbol]
              else
                0
              end
          end)

        {symbol, average_symbol_price / count}
      end)

    Enum.reduce(averaged_ticker, %{}, fn {symbol, price}, accum ->
      Map.put(accum, symbol, price)
    end)
  end

  defp insert_tickers(nil), do: nil

  defp insert_tickers(ticker_prices), do: insert_tickers(ticker_prices, DateTime.utc_now())

  defp insert_tickers(ticker_prices, datetime) do
    ticker_prices
    |> Enum.each(fn t ->
      ticker =
        BinanceApi.Ticker.from_dto(t)
        |> TickerPrices.from_object()

      TickerPriceRepository.insert_ticker(%TickerPrices{ticker | datetime: datetime})
    end)
  end

  defp binance_tailing_stop_loss([], _), do: :done

  defp binance_tailing_stop_loss([%Portfolio{} = record | tail], ticker_prices) do
    symbol = record.currency.symbol
    average_price = BinanceApiHelper.get_average_price(symbol)
    required_percentage = to_float(record.percentage_change_requirement)
    peak = to_float(record.peak_price)

    case average_price > peak do
      true ->
        {:ok, updated_record} =
          PortfolioRepository.add_update_portfolio(%Portfolio{record | peak_price: average_price})

        updated_record

      _ ->
        record
    end

    ticker_data = Enum.find(ticker_prices, fn x -> x["symbol"] == symbol <> "USDT" end)
    current_price = String.to_float(ticker_data["price"])

    case current_price < peak - peak / 100 * required_percentage do
      true ->
        IO.inspect("SELLING " <> symbol)
        %{"success" => true} = BinanceApiHelper.sell_all(symbol)
        PortfolioRepository.sell_trade(record.id, average_price)
        :sold

      _ ->
        :no_sale
    end

    binance_tailing_stop_loss(tail, ticker_prices)
  end

  @spec algo_trade_seller(list(%AlgoTrade{}), map(), map(), list(%AlgoTrade{})) ::
          list(%AlgoTrade{})
  defp algo_trade_seller([h = %AlgoTrade{}| t] = _open_trades, average_prices, ticker_prices, remaining_trades) do
    current_price = Decimal.from_float(ticker_prices[h.symbol])

    IO.inspect("Check sell " <> h.symbol)
    IO.inspect(Decimal.div(current_price, h.purchase_price) |> Decimal.sub(1) |> Decimal.mult(100) )
    IO.inspect(h.algo_strategy.sell_high)

    cond do
      Decimal.div(current_price, h.purchase_price) |> Decimal.sub(1) |> Decimal.mult(100) |> Decimal.compare(h.algo_strategy.sell_high) == :gt ||
      Decimal.div(h.purchase_price, current_price) |> Decimal.sub(1) |> Decimal.mult(100) |> Decimal.compare(h.algo_strategy.sell_low) == :gt ->
        case BinanceApiHelper.sell_algo_trade(h) do
          {:ok, resp} ->
            IO.inspect("Sold" <> h.symbol)
            AlgoRepository.sell_trade(resp, h, h.algo_strategy, ticker_prices)
            algo_trade_seller(t, average_prices, ticker_prices, remaining_trades)

          resp ->
            IO.inspect("Failed to sell" <> h.symbol)
            IO.inspect(resp)
            algo_trade_seller(t, average_prices, ticker_prices, [h | remaining_trades])
        end

      true ->
        algo_trade_seller(t, average_prices, ticker_prices, [h | remaining_trades])
    end
  end

  defp algo_trade_seller([] = _open_trades, _average_prices, _ticker_prices, remaining_trades),
    do: remaining_trades

  @spec algo_trade_buyer(%AlgoStrategy{}, map(), list(String.t()), map(), list(String.t())) ::
          {:done}
  def algo_trade_buyer( strategy = %AlgoStrategy{}, ticker_prices, [h|t] = _symbols, average_prices, ignore_symbols) do
    current_price = Decimal.from_float(ticker_prices[h])
    average_price = Decimal.from_float(average_prices[h])
    percentage_change = Decimal.div(current_price, average_price) |> Decimal.add(-1) |> Decimal.mult(100)

    cond do
      Kernel.length(ignore_symbols) - 1 >= Application.get_env(:cmcscraper, :algo_max_open_trades) ->
        IO.inspect("Max trade limit")
        algo_trade_buyer(strategy, ticker_prices, [], average_prices, ignore_symbols)

      Decimal.compare(average_price, 0) == :eq ->
        algo_trade_buyer(strategy, ticker_prices, t, average_prices, ignore_symbols)

      !is_nil(Enum.find(ignore_symbols, nil, fn x -> x == h end)) ->
        algo_trade_buyer(strategy, ticker_prices, t, average_prices, ignore_symbols)

        Decimal.compare(percentage_change, strategy.percentage_change) == :gt ->
        ## Do buy
        case BinanceApiHelper.buy(h, Decimal.div(strategy.purchase_size, current_price)) do
          {:ok, resp} ->
            IO.inspect("---------------Purchased " <> h)
            AlgoRepository.add_trade(resp, strategy.id, ticker_prices)
            algo_trade_buyer(strategy, ticker_prices, t, average_prices, [h | ignore_symbols])

          resp ->
            IO.inspect("---------------Failed to buy " <> h)
            IO.inspect(resp)
            algo_trade_buyer(strategy, ticker_prices, t, average_prices, ignore_symbols)
        end

      true ->
        ## Don't buy
        algo_trade_buyer(strategy, ticker_prices, t, average_prices, ignore_symbols)
    end
  end

  def algo_trade_buyer(_strategy, _ticker_prices, [], _average_prices, _ignore_symbols),
    do: {:done}

  defp to_float(decimal) do
    Decimal.to_float(decimal)
  end
end
