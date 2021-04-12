defmodule Cmcscraper.Models.CmcApi.CmcStatus do
  alias Cmcscraper.Models.CmcApi

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

defmodule Cmcscraper.Models.CmcApi.CmcQuoteDetails do
  defstruct last_updated: "",
            market_cap: 0.0,
            percent_change_1h: 0.0,
            percent_change_24h: 0.0,
            percent_change_7d: 0.0,
            price: 0.0,
            volume_24h: 0.0

  @type t :: %__MODULE__{
          last_updated: DateTime.t(),
          market_cap: float(),
          percent_change_1h: float(),
          percent_change_24h: float(),
          percent_change_7d: float(),
          price: float(),
          volume_24h: float()
        }

  def from_dto(map) when is_map(map) do
    %__MODULE__{
      last_updated: NaiveDateTime.from_iso8601!(map["last_updated"]),
      market_cap: map["market_cap"],
      percent_change_1h: map["percent_change_1h"],
      percent_change_24h: map["percent_change_24h"],
      percent_change_7d: map["percent_change_7d"],
      price: map["price"],
      volume_24h: map["volume_24h"]
    }
  end
end

defmodule Cmcscraper.Models.CmcApi.CmcQuote do
  alias Cmcscraper.Models.CmcApi
  defstruct usd: %CmcApi.CmcQuoteDetails{}
  use ExConstructor

  @type t :: %__MODULE__{
          usd: %CmcApi.CmcQuoteDetails{}
        }
  def from_dto(map) when is_map(map) do
    %__MODULE__{
      usd: CmcApi.CmcQuoteDetails.from_dto(map["USD"])
    }
  end
end

defmodule Cmcscraper.Models.CmcApi.CmcCoin do
  alias Cmcscraper.Models.CmcApi

  defstruct circulating_supply: 0,
            cmc_rank: 0,
            date_added: "",
            id: 0,
            last_updated: "",
            max_supply: 0,
            name: "",
            num_market_pairs: 0,
            platform: nil,
            quote: %CmcApi.CmcQuote{},
            slug: "",
            symbol: "",
            tags: [],
            total_supply: 0.0

  @type t :: %__MODULE__{
          circulating_supply: non_neg_integer(),
          cmc_rank: non_neg_integer(),
          date_added: Date.t(),
          id: non_neg_integer(),
          last_updated: Date.t(),
          max_supply: non_neg_integer(),
          name: String.t(),
          num_market_pairs: non_neg_integer(),
          platform: any(),
          quote: %CmcApi.CmcQuote{},
          slug: String.t(),
          symbol: String.t(),
          tags: list(Strin.t()),
          total_supply: float()
        }

  def from_dto(map) when is_map(map) do
    %__MODULE__{
      circulating_supply: map["circulating_supply"],
      cmc_rank: map["cmc_rank"],
      date_added: NaiveDateTime.from_iso8601!(map["date_added"]),
      id: map["id"],
      last_updated: NaiveDateTime.from_iso8601!(map["last_updated"]),
      max_supply: map["max_supply"],
      name: map["name"],
      num_market_pairs: map["num_market_pairs"],
      platform: map["platform"],
      quote: CmcApi.CmcQuote.from_dto(map["quote"]),
      slug: map["slug"],
      symbol: map["symbol"],
      tags: map["tags"],
      total_supply: map["total_supply"]
    }
  end
end

defmodule Cmcscraper.Models.CmcApi.ListingLatest do
  alias Cmcscraper.Models.CmcApi

  defstruct data: [],
            status: %CmcApi.CmcStatus{}

  @type t :: %__MODULE__{
          data: list(%CmcApi.CmcCoin{}),
          status: %CmcApi.CmcStatus{}
        }

  def from_dto(map) when is_map(map) do
    %__MODULE__{
      data: Enum.map(map["data"], fn x -> CmcApi.CmcCoin.from_dto(x) end),
      status: CmcApi.CmcStatus.from_dto(map["status"])
    }
  end
end
