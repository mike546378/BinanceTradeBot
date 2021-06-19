defmodule Cmcscraper.Schemas.AlgoTrade do
  alias Cmcscraper.Schemas.AlgoStrategy
  use Ecto.Schema
  import Ecto.Changeset

  schema "algo_trade" do
    field :purchase_date, :utc_datetime
    field :purchase_price, :decimal
    field :symbol, :string
    field :volume, :decimal
    field :sell_price, :decimal
    field :sell_date, :utc_datetime
    field :buy_fee_usdt, :decimal
    field :sell_fee_usdt, :decimal
    belongs_to :algo_strategy, AlgoStrategy
    timestamps()
  end

  def changeset(algo_trade, params \\ %{}) do
    algo_trade
    |> cast(params, [
      :id,
      :purchase_date,
      :purchase_price,
      :symbol,
      :volume,
      :sell_price,
      :sell_date,
      :buy_fee_usdt,
      :sell_fee_usdt,
      :algo_strategy_id
    ])
    |> clear_errors()
    |> validate_required([
      :purchase_date,
      :purchase_price,
      :symbol,
      :volume,
      :algo_strategy_id
    ])
    |> foreign_key_constraint(:algo_strategy_id)
    |> assoc_constraint(:algo_strategy)
  end

  def to_dto(%__MODULE__{} = map) do
    %{
      "id" => map.id,
      "purchase_date" => map.purchase_date,
      "purchase_price" => map.purchase_price,
      "symbol" => map.symbol,
      "volume" => map.volume,
      "sellPrice" => map.sell_price,
      "sellDate" => map.sell_date,
      "strategyId" => map.algo_strategy_id,
      "buyFeesUSDT" => map.buy_fee_usdt,
      "sellFeesUSDT" => map.sell_fee_usdt,
      "dateCreated" => map.inserted_at,
      "dateUpdated" => map.updated_at,
      "strategy" => AlgoStrategy.to_dto(map.algo_strategy)
    }
  end

  def to_dto(nil) do
    nil
  end

  defp clear_errors(%Ecto.Changeset{} = changeset) do
    Map.replace!(changeset, :errors, [])
    |> Map.replace!(:valid?, true)
  end
end
