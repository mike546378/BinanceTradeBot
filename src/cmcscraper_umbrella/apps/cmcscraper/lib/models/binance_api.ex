defmodule Cmcscraper.Models.BinanceApi.SomeModel do
  defstruct credit_count: 0,
            elapsed: 0,
            error_code: 0,
            error_message: nil,
            notice: nil,
            timestamp: "",
            total_count: 0

  @type t :: %__MODULE__{
          credit_count: non_neg_integer(),
          elapsed: non_neg_integer(),
          error_code: non_neg_integer(),
          error_message: String.t() | nil,
          notice: any(),
          timestamp: DateTime.t(),
          total_count: non_neg_integer()
        }

  def from_dto(map) when is_map(map) do
    %__MODULE__{
      credit_count: map["credit_count"],
      elapsed: map["elapsed"],
      error_code: map["error_code"],
      error_message: map["error_message"],
      notice: map["notice"],
      timestamp: NaiveDateTime.from_iso8601!(map["timestamp"]),
      total_count: map["total_count"]
    }
  end
end

defmodule Cmcscraper.Models.BinanceApi.Ticker do
  defstruct price: 0.0,
            symbol: ""

  @type t :: %__MODULE__{
          price: String.t(),
          symbol: String.t()
        }

  def from_dto(map) when is_map(map) do
    %__MODULE__{
      price: map["price"],
      symbol: map["symbol"]
    }
  end
end

defmodule Cmcscraper.Models.BinanceApi.TradeOrder do
  alias Cmcscraper.Models.BinanceApi.OrderFills

  defstruct client_order_id: "",
            cummulative_quote_qty: 0.0,
            executed_qty: 0.0,
            fills: nil,
            order_id: 0,
            order_list_id: -1,
            orig_qty: 0.0,
            price: 0.0,
            side: "",
            status: "",
            symbol: "",
            time_in_force: "",
            transact_time: 0,
            type: ""

  @type t :: %__MODULE__{
          client_order_id: String.t(),
          cummulative_quote_qty: Decimal.t(),
          executed_qty: Decimal.t(),
          fills: list(map()),
          order_id: non_neg_integer(),
          order_list_id: integer(),
          orig_qty: Decimal.t(),
          price: Decimal.t(),
          side: String.t(),
          status: String.t(),
          symbol: String.t(),
          time_in_force: String.t(),
          transact_time: non_neg_integer(),
          type: String.t()
        }

  def from_dto(map) when is_map(map) do
    %__MODULE__{
      client_order_id: map["clientOrderId"],
      cummulative_quote_qty: map["cummulativeQuoteQty"],
      executed_qty: map["executedQty"],
      fills: OrderFills.from_dto(map["fills"]),
      order_id: map["orderId"],
      order_list_id: map["orderListId"],
      orig_qty: map["origQty"],
      price: map["price"],
      side: map["side"],
      status: map["status"],
      symbol: map["symbol"],
      time_in_force: map["timeInForce"],
      transact_time: map["transactTime"],
      type: map["type"]
    }
  end

  def from_dto(nil), do: nil

  def calc_fees(%__MODULE__{} = order, tickers) do
    Enum.reduce(order.fills, Decimal.new(0), fn fill, accum ->
      asset = fill.commission_asset
      value = fill.commission
      if asset == "USDT" do
        Decimal.add(accum, value)
      else
        Decimal.from_float(tickers[asset <> "USDT"])
        |> Decimal.mult(value)
        |> Decimal.add(accum)
      end
    end)
  end
end

defmodule Cmcscraper.Models.BinanceApi.OrderFills do
  defstruct commission: 0,
            commission_asset: "",
            price: 0,
            qty: 0,
            tradeId: 0

  @type t :: %__MODULE__{
          commission: Decimal.t(),
          commission_asset: String.t(),
          price: Decimal.t(),
          qty: Decimal.t(),
          tradeId: non_neg_integer()
        }

  def from_dto(nil), do: nil

  def from_dto(map) when is_map(map) do
    %__MODULE__{
      commission: map["commission"],
      commission_asset: map["commissionAsset"],
      price: map["price"],
      qty: map["qty"],
      tradeId: map["tradeId"]
    }
  end

  def from_dto(fills) when is_list(fills), do: from_dto(fills, [])
  defp from_dto([h | t], accum), do: from_dto(t, [from_dto(h) | accum])
  defp from_dto([], accum), do: accum
end
