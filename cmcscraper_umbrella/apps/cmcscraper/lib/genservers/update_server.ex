defmodule Cmcscraper.Genservers.UpdateServer do
  alias Cmcscraper.Genservers.UpdateServerLogic

  def start_link(state) do
    GenServer.start_link(UpdateServerLogic, state)
  end

  def update_latest_prices do
    server_pid()
    |> send({:op_update_latest_prices})
  end

  defp server_pid do
    Process.whereis(:update_server)
  end
end
