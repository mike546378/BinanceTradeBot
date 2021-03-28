defmodule CmcscraperWeb.Router do
  use CmcscraperWeb, :router
  alias CmcscraperWeb.Api

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CmcscraperWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", CmcscraperWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/api/" do
      pipe_through :api

      get "/data/fullupdateallcurrencies", Api.DataController, :full_update_all_currencies
      get "/data/updatelatestprices", Api.DataController, :update_latest_prices
      get "/data/historicmap", Api.DataController, :historic_map
      get "/data/updatecoinlist", Api.DataController, :update_coin_list
      get "/data/getcurrencydata", Api.DataController, :get_currency_data
      get "/data/analysis", Api.DataController, :get_analysis
      get "/data/coin/getbyname/:name", Api.DataController, :get_coin_by_name

      get "/portfolio/add", Api.PortfolioController, :add
      get "/portfolio/remove/:symbol", Api.PortfolioController, :remove
      get "/portfolio/get", Api.PortfolioController, :list
      get "/portfolio/sync", Api.PortfolioController, :sync
      get "/portfolio/updatepercentage/:portfolio_id/:percentage", Api.PortfolioController, :sync

      get "/binance/getbalance/:symbol", Api.BinanceController, :get_balance_by_symbol
      get "/binance/getbalances", Api.BinanceController, :get_balance_full
      get "/binance/sell/:symbol", Api.BinanceController, :sell_by_symbol

    end

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: CmcscraperWeb.Telemetry
    end
  end
end
