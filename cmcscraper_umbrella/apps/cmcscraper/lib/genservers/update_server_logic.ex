defmodule Cmcscraper.Genservers.UpdateServerLogic do
  use GenServer

  alias Cmcscraper.RepoFunctions.HistoricPriceRepository
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.Schemas.Currency
  alias Cmcscraper.Schemas.HistoricPrice
  alias Cmcscraper.Helpers.CmcApiHelper
  alias Cmcscraper.Models.CmcApi

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    Process.register(self(), :update_server)
    send(self(), {:price_update_loop})
    {:ok, state}
  end

  @impl true
  def handle_info({:price_update_loop}, socket) do
    send(self(), {:op_update_latest_prices})
    Process.send_after(self(), {:price_update_loop}, 30*60*1000)
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
  def handle_cast({:op_update_latest_price_data}, socket) do
    send(self(), {:op_update_latest_prices})
    {:noreply, socket}
  end

  @impl true
  def handle_cast({:op_get_coins_update}, socket) do
    #Endpoint.broadcast("updatestatus", "update", %{status: "updating coin list"})
    Enum.each(1..3, fn page ->
      send(self(), {:op_read_page, page})
    end)
    {:noreply, socket}
  end

  @impl true
  def handle_cast({:op_full_update}, socket) do
    #Endpoint.broadcast("updatestatus", "update", %{status: "performing full update"})
    delay = 0
    CurrencyRepository.get_all_currencies()
    |> Enum.map(fn x -> delay = delay + 5000; Process.send_after(self(), {:op_get_price_data, x}, delay) end)
    {:noreply, socket}
  end
end
