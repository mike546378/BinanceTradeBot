defmodule Cmcscraper.RepoFunctions.TickerPriceRepository do
  import Ecto.Query
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

  def get_recent_tickers(days) do
    datetime = DateTime.utc_now()
      |> DateTime.add(-(days*24*60*60), :second)

      (
        from p in TickerPrices,
        where: p.datetime >= ^datetime
      )
      |> Repo.all()
  end

  def get_tickers_in_range(hours_offset, total_hours) do
    min_datetime = DateTime.utc_now()
      |> DateTime.add(-(hours_offset*60*60), :second)
    max_datetime = DateTime.utc_now()
      |> DateTime.add(-(hours_offset*60*60) + total_hours*60*60, :second)

      (
        from p in TickerPrices,
        where: p.datetime >= ^min_datetime and p.datetime <= ^max_datetime
      )
      |> Repo.all()
  end

  def get_last_n_tickers(max_ticks) do
    datetimes = (
      from p in TickerPrices,
      order_by: [desc: :datetime],
      limit: ^max_ticks,
      group_by: [:datetime],
      select: p.datetime
    )
    |> Repo.all()

    (
      from p in TickerPrices,
      where: p.datetime in ^datetimes
    )
    |> Repo.all()
    |> Enum.group_by(fn x -> x.datetime end, fn y -> y end)
    |> Map.to_list()
    |> Enum.map(fn {date, prices} ->
      {date,
       Enum.reduce(prices, %{}, fn ticker, accum ->
         Map.put(accum, ticker.symbol, ticker.price)
       end)}
    end)
end
end
