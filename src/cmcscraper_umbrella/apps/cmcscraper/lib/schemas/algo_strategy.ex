defmodule Cmcscraper.Schemas.AlgoStrategy do
  alias Cmcscraper.Schemas.AlgoTrade
  use Ecto.Schema
  import Ecto.Changeset

  schema "algo_strategy" do
    field :sell_low, :decimal
    field :sell_high, :decimal
    field :ticks_count, :integer
    field :percentage_change, :decimal
    field :purchase_size, :decimal
    field :profit, :decimal
    field :is_active, :boolean
    has_many :algo_trade, AlgoTrade
    timestamps()
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(historic_price, params \\ %{}) do
    historic_price
    |> cast(params, [
      :id,
      :sell_low,
      :sell_high,
      :ticks_count,
      :percentage_change,
      :purchase_size,
      :profit,
      :is_active
    ])
    |> clear_errors()
    |> validate_required([
      :sell_low,
      :sell_high,
      :ticks_count,
      :percentage_change,
      :purchase_size,
      :profit,
      :is_active,
    ])
  end

  def to_dto(%__MODULE__{} = strategy) do
    %{
        "id" => strategy.id,
        "dateCreated" => strategy.inserted_at,
        "dateUpdated" => strategy.updated_at,
        "sellLow" => strategy.sell_low,
        "sellHigh" => strategy.sell_high,
        "ticksCount" => strategy.ticks_count,
        "percentageChange" => strategy.percentage_change,
        "purchaseSize" => strategy.purchase_size,
        "profit" => strategy.profit,
        "isActive" => strategy.is_active,
        "algoTrades" => map_trade_data(strategy.algo_trade)
    }
  end

  def to_dto(_) do
    nil
  end

  defp map_trade_data(price_data) when is_list(price_data) do
    Enum.map(price_data, fn x -> AlgoTrade.to_dto(x) end)
  end

  defp map_trade_data(_), do: nil

  defp clear_errors(%Ecto.Changeset{} = changeset) do
    Map.replace!(changeset, :errors, [])
    |> Map.replace!(:valid?, true)
  end
end
