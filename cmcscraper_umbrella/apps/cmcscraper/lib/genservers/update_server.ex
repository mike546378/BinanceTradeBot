defmodule Cmcscraper.Genservers.UpdateServer do
  alias Cmcscraper.Genservers.UpdateServerLogic

  def start_link(state) do
    GenServer.start_link(UpdateServerLogic, state)
  end

  def full_update_all_currencies do
    server_pid()
    |> GenServer.cast({:op_full_update})
  end

  def update_latest_prices do
    server_pid()
    |> send({:op_update_latest_prices})
  end

  def historic_map do
    server_pid()
    |> GenServer.cast({:op_historic_mapping})
  end

  def update_coin_list do
    server_pid()
    |> GenServer.cast({:op_get_coins_update})
  end

  defp server_pid do
    Process.whereis(:update_server)
  end
end
