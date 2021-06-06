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
