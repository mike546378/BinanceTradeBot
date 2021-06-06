defmodule Cmcscraper.RepoFunctions.TickerPriceRepository do
  alias Cmcscraper.Repo
  alias Cmcscraper.Schemas.TickerPrices

  def insert_ticker(%TickerPrices{} = ticker) do
    case ticker.symbol =~ "USDT" do
      true ->
        TickerPrices.changeset(%TickerPrices{}, Map.from_struct(ticker))
        |> Repo.insert!()
      false -> nil
    end
  end
end
