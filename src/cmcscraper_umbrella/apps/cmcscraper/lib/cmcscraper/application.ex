defmodule Cmcscraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    :ets.new(:lot_size_lookup, [:set, :public, :named_table])
    :ets.new(:exchange_info_lookup, [:set, :public, :named_table])

    children = [
      # Start the Ecto repository
      Cmcscraper.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Cmcscraper.PubSub},
    ]

    # Start the update server if not in test mode
    case Application.get_env(:cmcscraper, :env) do
      :test -> children
      _ -> children ++ [
      #  Cmcscraper.Genservers.UpdateServerLogic,
        Cmcscraper.Genservers.TradeStream
      ]
    end
    |> Supervisor.start_link(strategy: :one_for_one, name: Cmcscraper.Supervisor)
  end
end
