defmodule Cmcscraper.Genservers.UpdateServerLogic do
  use GenServer

  alias Cmcscraper.RepoFunctions.HistoricPriceRepository
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.Schemas.Currency
  alias Cmcscraper.Helpers.FlokiHelper
  #alias CmcscraperWeb.Endpoint

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    Process.register(self(), :update_server)
    #send(self(), {:price_update_loop})
    {:ok, state}
  end

  @impl true
  def handle_info({:price_update_loop}, socket) do
    #Endpoint.broadcast("updatestatus", "update", %{status: "updating latest price info"})
    send(self(), {:op_update_latest_prices})
    Process.send_after(self(), {:price_update_loop}, 30*60*1000)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:op_update_latest_prices}, socket) do
    #Endpoint.broadcast("updatestatus", "update", %{status: "updating latest price info"})
    IO.inspect("Updating latest prices")
    Enum.each(1..3, fn page ->
      send(self(), {:op_read_page_prices, page})
    end)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:op_read_page, page_num}, socket) do
    IO.inspect("Reading pages")
    FlokiHelper.get_all_currencies(page_num)
    |> Enum.each(fn x ->
      CurrencyRepository.insert_currency(x)
      #Endpoint.broadcast("updatestatus", "update", %{status: "found " <> x})
    end)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:op_read_page_prices, page_num}, socket) do
    FlokiHelper.get_all_currencies_prices(page_num)
    |> Enum.each(fn x ->
      {name, price, volume, marketcap, ranking} = x
      HistoricPriceRepository.update_todays_price(name, price, volume, marketcap, ranking)
      #Endpoint.broadcast("updatestatus", "update", %{status: "found " <> x})
    end)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:op_get_price_data, coin = %Currency{}}, socket) do
    case FlokiHelper.get_price_history(coin.currency_name) do
      {:error, _} ->
        Process.send_after(self(), {:op_get_price_data, coin}, 60000)
      list -> IO.inspect(list); Enum.map(list, fn x -> HistoricPriceRepository.insert_price(x, coin.id ) end)
    end
    {:noreply, socket}
  end

  @impl true
  def handle_info({:op_get_price_data, coin_name}, socket) do
    #Endpoint.broadcast("updatestatus", "update", %{status: "retrieving price data for " <> coin_name})
    case FlokiHelper.get_price_history(coin_name) do
      {:error, _} -> IO.inspect("Error retrieving " <> coin_name)
      list -> Enum.map(list, fn x -> HistoricPriceRepository.insert_price(x, 2) end)
    end
    {:noreply, socket}
  end

  @impl true
  def handle_cast({:op_historic_mapping}, socket) do
    HistoricPriceRepository.perform_historic_mapping
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
