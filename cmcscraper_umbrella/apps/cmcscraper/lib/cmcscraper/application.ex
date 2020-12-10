defmodule Cmcscraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    children = [
      # Start the Ecto repository
      Cmcscraper.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Cmcscraper.PubSub},
      # Start the update server
      Cmcscraper.Genservers.UpdateServerLogic
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Cmcscraper.Supervisor)
  end
end
