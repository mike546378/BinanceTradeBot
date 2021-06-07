defmodule Cmcscraper.Models.AlgoTrading.Strategy do

  defstruct sell_low: 0,
            sell_high: 0,
            percent_change: 0,
            ticks_count: 0

  @type t :: %__MODULE__{
          sell_low: Float.t(),
          sell_high: Float.t(),
          percent_change: Float.t(),
          ticks_count: non_neg_integer(),
        }
end

defmodule Cmcscraper.Models.AlgoTrading.Epoch do
  alias Cmcscraper.Models.AlgoTrading

  defstruct profit: 0,
            trades: 0,
            trades_high: 0,
            trades_low: 0,
            total_profit: 0,
            total_loss: 0,
            sell_high_ticks: 0,
            sell_low_ticks: 0,
            profit_per_trade: 0,
            strategy: %AlgoTrading.Strategy{}

  @type t :: %__MODULE__{
          profit: Float.t(),
          trades: non_neg_integer(),
          trades_high: non_neg_integer(),
          trades_low: non_neg_integer(),
          total_profit: non_neg_integer(),
          total_loss: non_neg_integer(),
          sell_high_ticks: non_neg_integer(),
          sell_low_ticks: non_neg_integer(),
          profit_per_trade: non_neg_integer(),
          strategy: AlgoTrading.Strategy.t(),
        }

  def compare(%__MODULE__{} = item1, %__MODULE__{} = item2) when item1.profit > item2.profit, do: :gt
  def compare(%__MODULE__{} = item1, %__MODULE__{} = item2) when item1.profit == item2.profit, do: :eq
  def compare(%__MODULE__{} = item1, %__MODULE__{} = item2) when item1.profit < item2.profit, do: :lt
end

defmodule Cmcscraper.Models.AlgoTrading.ActiveTrade do

  defstruct symbol: nil,
            purchase_price: 0,
            volume: 0,
            purchase_tick: 0

  @type t :: %__MODULE__{
            symbol: String.t(),
            purchase_price: Float.t(),
            volume: Float.t(),
        }
end
