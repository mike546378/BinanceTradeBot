defmodule Cmcscraper.Genservers.TradeStream do
  use WebSockex

  # alias Cmcscraper.RepoFunctions.HistoricPriceRepository
  # alias Cmcscraper.RepoFunctions.CurrencyRepository
  # alias Cmcscraper.RepoFunctions.PortfolioRepository
  # alias Cmcscraper.RepoFunctions.TickerPriceRepository
  # alias Cmcscraper.RepoFunctions.AlgoRepository
  # alias Cmcscraper.Schemas.Currency
  # alias Cmcscraper.Schemas.HistoricPrice
  # alias Cmcscraper.Schemas.AlgoStrategy
  # alias Cmcscraper.Schemas.AlgoTrade
  # alias Cmcscraper.Schemas.TickerPrices
  # alias Cmcscraper.Schemas.Portfolio
  # alias Cmcscraper.Helpers.CmcApiHelper
   alias Cmcscraper.Helpers.BinanceApiHelper
  # alias Cmcscraper.Helpers.AlgoTradingHelper
  # alias Cmcscraper.Models.CmcApi
  # alias Cmcscraper.Models.BinanceApi

  def start_link(_state) do
    {:ok, pid} = WebSockex.start_link(Application.get_env(:cmcscraper, :binance_ws_uri), __MODULE__, %{strategy: nil, tickers: %{}, averages: %{}})

    subscriptions =
      BinanceApiHelper.get_ticker_prices()
      |> Enum.map(fn x -> x["symbol"] end)
      |> Enum.filter(fn x -> x =~ "USDT" && !( x =~ "UPUSDT" || x =~ "DOWNUSDT") end)
      |> Enum.map(fn x ->
        String.downcase(x) <> "@kline_1m"
      end)
    payload = %{"method" => "SUBSCRIBE", "params" => subscriptions, "id" => 1}
    WebSockex.send_frame(pid, {:text, Poison.encode!(payload)})
    send(pid, {:worker_loop})
    {:ok, pid}
  end

  @impl true
  def handle_connect(_conn, state) do
    Process.delete(:trade_stream)
    Process.register(self(), :trade_stream)
    IO.inspect("Connected")

    {:ok, state}
  end

  @impl true
  def terminate(close_reason, _state) do
    IO.inspect("Terminated")
    IO.inspect(close_reason)
  end

  @impl true
  def handle_disconnect(close_reason, _state) do
    IO.inspect("Closed")
    IO.inspect(close_reason)
    throw(close_reason)
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    new_state = process_message(Poison.decode!(msg), state)
    #IO.puts "Received Message - Type: #{inspect type} -- Message: #{inspect msg}"
    {:ok, new_state}
  end

  defp process_message(%{"stream" => _, "data" => %{"k" => %{"s" => symbol, "c" => price}}}, state) do
    %{state | tickers: Map.put(state.tickers, symbol, price)}
  end

  defp process_message(msg, state) do
    IO.inspect(msg)
    state
  end

  @impl true
  def handle_info({:worker_looper}, state) do
    IO.inspect(state)
    Process.send_after(self(), {:worker_looper}, 1 * 1000)
    {:ok, state}
  end

  @impl true
  def handle_info({:strategy, strat}, state) do
    {:ok, %{state | strategy: strat}}
  end

  @impl true
  def handle_info({:averages, averages}, state) do
    {:ok, %{state | averages: averages}}
  end

end
