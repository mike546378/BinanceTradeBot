defmodule CmcscraperWeb.UserChannel do
  use Phoenix.Channel
  alias Cmcscraper.Genservers.UpdateServer
  ###
  ## Channel Setup / Teardown
  ###

  # On join
  @impl true
  def join("updatestatus", _payload, socket) do
    case :ets.lookup(:data_state, :update_status) do
      [{:update_status, state}] ->
        send(self(), {:after_join, {:state, state}})
        {:ok, socket}
      _ ->
        {:error, %{message: "An error occurred"}}
    end
  end

  # After join
  @impl true
  def handle_info({:after_join, {:state, state}}, socket) do
    case state do
      :none ->
        push(socket, "connected", %{currentState: "none"})
        {:noreply, socket}
      :updating ->
        push(socket, "connected", %{currentState: "updating"})
        {:noreply, socket}
        _ ->
        push(socket, "error", %{message: ":after_join unknown state"})
        {:noreply, socket}
    end
  end

  # Termination
  @impl true
  def terminate(_reason, socket) do
    {:ok, socket}
  end

  ###
  ## Catch Outgoing messages
  ###
  @impl true
  def handle_out(_event, _payload, socket) do
    {:noreply, socket}
  end

  ###
  ## Incoming Events
  ###

  @impl true
  def handle_in("get_currencies", %{"page" => page_num}, socket) when is_number(page_num) do
    send(self(), {:op_read_page, page_num})
    {:noreply, socket}
  end

  @impl true
  def handle_in("get_history", %{"currency" => currency}, socket) do
    send(self(), {:op_get_price_data, currency})
    {:noreply, socket}
  end

  @impl true
  def handle_in("get_all_coins", %{}, socket) do
    UpdateServer.update_coin_list()
    {:noreply, socket}
  end

  @impl true
  def handle_in("full_update", %{}, socket) do
    UpdateServer.full_update_all_currencies()
    {:noreply, socket}
  end

  # Default
  @impl true
  def handle_in(_event, _payload, socket) do
    {:noreply, socket}
  end
end
