defmodule Cmcscraper.Genservers.UpdateServerLogic do
  use GenServer

  alias Cmcscraper.RepoFunctions.HistoricPriceRepository
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.RepoFunctions.PortfolioRepository
  alias Cmcscraper.Schemas.Currency
  alias Cmcscraper.Schemas.HistoricPrice
  alias Cmcscraper.Schemas.Portfolio
  alias Cmcscraper.Helpers.CmcApiHelper
  alias Cmcscraper.Helpers.BinanceApiHelper
  alias Cmcscraper.Models.CmcApi

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    Process.register(self(), :update_server)
    send(self(), {:delayed_price_update_loop})
    send(self(), {:delayed_binance_loop})
    {:ok, state}
  end

  @impl true
  def handle_info({:delayed_price_update_loop}, socket) do
    Process.send_after(self(), {:price_update_loop}, 3*60*1000)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:price_update_loop}, socket) do
    send(self(), {:op_update_latest_prices})
    Process.send_after(self(), {:price_update_loop}, 30*60*1000)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:delayed_binance_loop}, socket) do
    Process.send_after(self(), {:binance_loop}, 1*60*1000)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:binance_loop}, socket) do
    send(self(), {:binance_worker})
    Process.send_after(self(), {:binance_loop}, 45*1000)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:op_update_latest_prices}, socket) do
    IO.inspect("Updating latest prices")
    %CmcApi.ListingLatest{} = prices = CmcApiHelper.get_latest_prices(200)
    Enum.each(prices.data, fn c ->
      {:ok, %Currency{} = currency} = CurrencyRepository.add_update_currency(Currency.from_object(c))
      HistoricPriceRepository.add_update_historic_price(%{ HistoricPrice.from_object(c) | currency_id: currency.id })
    end)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:binance_worker}, socket) do
    IO.inspect("Binance Worker")
    portfolio = PortfolioRepository.get_active_trades()
    binance_worker(portfolio, BinanceApiHelper.get_ticker_prices())
    {:noreply, socket}
  end

  defp binance_worker([], _), do: :done

  defp binance_worker([%Portfolio{} = record|tail], ticker_prices) do
    symbol = record.currency.symbol
    average_price = BinanceApiHelper.get_average_price(symbol)
    required_percentage = to_float(record.percentage_change_requirement)
    peak = to_float(record.peak_price)

    case average_price > peak do
      true ->
        {:ok, updated_record } = PortfolioRepository.add_update_portfolio(%Portfolio{record | peak_price: average_price})
        updated_record
      _ ->
        record
    end

    ticker_data = Enum.find(ticker_prices, fn x -> x["symbol"] == symbol <> "USDT" end)
    current_price = String.to_float(ticker_data["price"])
    case current_price <  peak - (peak/100*required_percentage) do
      true ->
        IO.inspect("SELLING " <> symbol)
        %{"success" => true} = BinanceApiHelper.sell_all(symbol)
        PortfolioRepository.sell_trade(record.id, average_price)
        :sold
      _ ->
        :no_sale
    end

    binance_worker(tail, ticker_prices)
  end

  defp to_float(decimal) do
    Decimal.to_float(decimal)
  end
end
