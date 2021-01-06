defmodule Cmcscraper.Helpers.PriceAnalysisHelper do

  alias Cmcscraper.Schemas.HistoricPrice

  def rank_slope_analysis(price_data) when is_list(price_data) do
    currency_name = Enum.at(price_data, 0).currency.currency_name
    {y, x} = do_stuff(price_data, [])
    case x do
      [] ->
        %{name: currency_name, slope: 0}
      _ ->
        xmean = Statistics.mean(x)
        ymean = Statistics.mean(y)
        upper = upper_calc(x, xmean, y, ymean, [], 0)
        lower = Enum.map(x, fn xelem ->
          :math.pow(xelem - xmean, 2)
        end)

        %{
          name: currency_name,
          slope: Enum.sum(upper)/Enum.sum(lower),
          start: price_data |> Enum.sort(HistoricPrice) |> Enum.at(0, %HistoricPrice{ranking: 999}) |> (&(&1.ranking)).(),
          end: Enum.sort(price_data, HistoricPrice) |> Enum.reverse |> Enum.at(0, %HistoricPrice{ranking: 999}) |> (&(&1.ranking)).()
        }
    end
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
