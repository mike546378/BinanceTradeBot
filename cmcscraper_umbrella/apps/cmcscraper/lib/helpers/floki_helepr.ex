defmodule Cmcscraper.Helpers.FlokiHelper do

  def get_all_currencies(page_num) do
    case HTTPoison.get("https://coinmarketcap.com/#{page_num}/") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
          |> Floki.find(".rc-table-cell-fix-left-last a.cmc-link")
          |> Floki.attribute("href")
          |> Enum.map(fn x -> [_,_,_,name,_] = :re.split(x, "([a-z- 0-9]+)"); name end)
      _ ->
        {:error, "Error retrieving currency list"}
    end
  end

  def get_all_currencies_prices(page_num) do
    case HTTPoison.get("https://coinmarketcap.com/#{page_num}/") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body |>
          Floki.find("tr.rc-table-row-level-0") |>
          Enum.map(
            fn x ->
              IO.inspect(x)
              row = Floki.find(x, "td")
              mcap = Enum.at(row, 6) |> Floki.text |> String.replace(",", "") |> String.replace("$", "")
              vol = Enum.at(row, 7) |> Floki.find("a") |> Floki.text |> String.replace(",", "") |> String.replace("$", "")
              price = Enum.at(row, 3) |> Floki.find("a") |> Floki.text |> String.replace(",", "") |> String.replace("$", "")
              coin = Enum.at(row, 3) |> Floki.find("a") |> Floki.attribute("href") |> :re.split("([a-z- 0-9]+)") |> Enum.at(3)
              {ranking, _} = Enum.at(row, 1) |> Floki.text |> Integer.parse()
              {coin, price, vol, mcap, ranking}
            end)
      _ ->
        {:error, "Error retrieving latest currency price data"}
    end
  end

  def get_price_history(coin_name) do
    IO.inspect(coin_name)
    case HTTPoison.get("https://coinmarketcap.com/currencies/#{coin_name}/historical-data/") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          Enum.at(Floki.find(body, "table"), 2)
          |> Floki.find("tr")
          |> Enum.map(fn row -> Floki.find(row, "div")
            |> Enum.map(fn col -> Floki.text(col) end)
          end)
          |> Enum.map(fn data ->
            IO.inspect(data)
            [p_date, _p_open, _p_high, _p_low, p_close, p_volume, p_marketcap] = data
            {volume, _} = String.replace(p_volume, ",", "") |> Float.parse
            {marketcap, _} = String.replace(p_marketcap, ",", "") |> Float.parse
            {price, _} = String.replace(p_close, ",", "") |> Float.parse
            [convert_date(p_date), price, volume, marketcap]
          end)
      _ ->
        {:error, "Error retrieving coin data " <> coin_name}
    end
  end

  defp convert_date(date) do
    months = ["Jan", "Feb", "Mar", "Apr","May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    [month, day, year] = date |> String.replace(",", "") |> String.split
    month = Enum.find_index(months, fn x -> x == month end) + 1
    {year, _} = Integer.parse(year)
    {day, _} = Integer.parse(day)
    {:ok, date} = Date.new(year, month, day)
    date
  end
end
