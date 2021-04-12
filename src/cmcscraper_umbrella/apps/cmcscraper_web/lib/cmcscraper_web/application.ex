defmodule CmcscraperWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    :ets.new(:data_state, [:set, :public, :named_table])
    :ets.insert(:data_state, {:update_status, :none})

    children = [
      # Start the Telemetry supervisor
      CmcscraperWeb.Telemetry,
      # Start the Endpoint (http/https)
      CmcscraperWeb.Endpoint
      # Start a worker by calling: CmcscraperWeb.Worker.start_link(arg)
      # {CmcscraperWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CmcscraperWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CmcscraperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
