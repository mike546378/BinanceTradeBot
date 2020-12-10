defmodule CmcscraperWeb.Api.DataController do
  use CmcscraperWeb, :controller
  alias Cmcscraper.Genservers.UpdateServer
  alias Cmcscraper.RepoFunctions.CurrencyRepository
  alias Cmcscraper.Schemas.HistoricPrice

  def full_update_all_currencies(conn, _params) do
      UpdateServer.full_update_all_currencies()
      json(conn, %{success: true})
  end

  def update_latest_prices(conn, _params) do
      UpdateServer.update_latest_prices()
      json(conn, %{success: true})
  end

  def historic_map(conn, _params) do
      UpdateServer.historic_map()
      json(conn, %{success: true})
  end

  def update_coin_list(conn, _params) do
      UpdateServer.update_coin_list()
      json(conn, %{success: true})
  end

  def get_coin_by_name(conn, %{"name" => name}) do
    currency = CurrencyRepository.to_dto(CurrencyRepository.get_currency_by_name(name))
    json(conn, currency)
  end

  def get_currency_data(conn, %{"limit" => limit, "offset" => offset}) do

    {offset, _} = Integer.parse(offset)
    {limit, _} = Integer.parse(limit)

    currency = Enum.map(CurrencyRepository.get_currency_data(limit, offset), fn x -> CurrencyRepository.to_dto(x) end)
    json(conn, currency)
  end

  def get_currency_data(conn, %{}) do
    get_currency_data(conn, %{"limit" => 100, "offset" => 0})
  end

  def get_currency_data(conn, %{"limit" => limit, "offset" => offset}) do

    {offset, _} = Integer.parse(offset)
    {limit, _} = Integer.parse(limit)

    currency = Enum.map(CurrencyRepository.get_currency_data(limit, offset), fn x -> CurrencyRepository.to_dto(x) end)
    json(conn, currency)
  end

  def get_analysis(conn, _params) do
    data = CurrencyRepository.get_currency_data(1000, 0)

    currency = Enum.map(data,
    fn record ->
      {y, x} = do_stuff(record.historic_price, [])
      case x do
        [] ->
          %{name: record.currency_name, slope: 0}
        _ ->
          xmean = Statistics.mean(x)
          ymean = Statistics.mean(y)
          record.currency_name |> IO.inspect()
          upper = upper_calc(x, xmean, y, ymean, [], 0)
          lower = Enum.map(x, fn xelem ->
            :math.pow(xelem - xmean, 2)
          end)
          cond do
            Enum.count(record.historic_price) > 25 and Enum.at(Enum.reverse(record.historic_price), 0, -1).ranking < 100 ->
              %{name: record.currency_name, slope: Enum.sum(upper)/Enum.sum(lower), start: Enum.at(Enum.reverse(record.historic_price), 0, 999).ranking, end: Enum.at(record.historic_price, 0, 999).ranking}
              |> IO.inspect()
            true ->
#              %{name: record.currency_name, slope: Enum.sum(upper)/Enum.sum(lower)}
 #             |> IO.inspect()
              %{slope: 999}
          end
      end
    end)
    |> IO.inspect()
    |> Enum.sort_by(&{&1.slope})
    json(conn, currency)
  end

  defp upper_calc([], _, _, _, accum, _) do
    accum
  end

  defp upper_calc([h|t], xmean, y, ymean, accum, counter) do
    upper_calc(
      t,
      xmean,
      y,
      ymean,
      [(h - xmean)*(Enum.at(y, counter) - ymean)|accum],
      counter+1)
  end

  defp do_stuff([], []) do
    {[], []}
  end

  defp do_stuff(data, accum) do
    do_stuff(data, accum, [])
  end

  defp do_stuff([%HistoricPrice{} = h|t], accum, []) do
    do_stuff(t, [h.ranking|accum], [1])
  end

  defp do_stuff([%HistoricPrice{} = h|t], accum, [h2|_t2] = accum2) do
    do_stuff(t, [h.ranking|accum], [h2+1|accum2])
  end

  defp do_stuff([], accum, accum2) do
    {Enum.reverse(accum), Enum.reverse(accum2)}
  end
end
