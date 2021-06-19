defmodule Cmcscraper.Helpers.BinanceApiHelper do

  def get_request(endpoint), do: get_request(endpoint, "")
  def get_request(endpoint, query) do
    api_key = Application.get_env(:cmcscraper, :binance_api_key)
    base_url = Application.get_env(:cmcscraper, :binance_api_uri)

    response = HTTPoison.get!(base_url <> endpoint <> "?" <> query, [{"X-MBX-APIKEY", api_key}], [ssl: [{:versions, [:'tlsv1.2']}]])
    Poison.decode!(response.body)
  end

  def get_request_with_signature(endpoint) do
    get_request_with_signature(endpoint, "")
  end

  def get_request_with_signature(endpoint, query) do
    api_key = Application.get_env(:cmcscraper, :binance_api_key)
    api_secret = Application.get_env(:cmcscraper, :binance_api_secret)
    base_url = Application.get_env(:cmcscraper, :binance_api_uri)

    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    body = query <> "recvWindow=15000&timestamp=" <> Integer.to_string(timestamp*1000)

    signature = :crypto.hmac(:sha256, api_secret, body)
      |> Base.encode16()
    body = body <> "&signature=" <> signature
    response = HTTPoison.get!(base_url <> endpoint <> "?" <> body, [{"X-MBX-APIKEY", api_key}], [ssl: [{:versions, [:'tlsv1.2']}]])
    Poison.decode!(response.body)
  end

  def post_request_with_signature(endpoint, query) do
    api_key = Application.get_env(:cmcscraper, :binance_api_key)
    api_secret = Application.get_env(:cmcscraper, :binance_api_secret)
    base_url = Application.get_env(:cmcscraper, :binance_api_uri)

    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    body = query <> "recvWindow=15000&timestamp=" <> Integer.to_string(timestamp*1000)

    signature = :crypto.hmac(:sha256, api_secret, body)
      |> Base.encode16()
    body = body <> "&signature=" <> signature
    resp = HTTPoison.post!(base_url <> endpoint <> "?" <> body, "", [{"X-MBX-APIKEY", api_key}], [ssl: [{:versions, [:'tlsv1.2']}]])
    Enum.find(resp.headers, nil, fn {x, _val} -> x == "x-mbx-used-weight" end) |> IO.inspect()
    Enum.find(resp.headers, nil, fn {x, _val} -> x == "x-mbx-order-count-10s" end) |> IO.inspect()
    Enum.find(resp.headers, nil, fn {x, _val} -> x == "x-mbx-order-count-1d" end) |> IO.inspect()
    resp
  end

  def get_average_price(symbol) do
    %{"mins" => _, "price" => price} = get_request("v3/avgPrice", "symbol=" <> symbol <> "USDT")
    {val, _ } = Float.parse(price)
    val
  end

  def get_account_balances do
    resp = get_request_with_signature("v3/account")
    %{"balances" => balances } = resp
    balances
  end

  def get_account_balance(symbol) do
    %{"free" => bal } = get_account_balances()
    |> Enum.find(fn x -> x["asset"] == symbol end)
    {val, _ } = Float.parse(bal)
    val
  end

  def get_exchange_info do
    IO.inspect("GET EXCHANGE INFO")
    get_request("v3/exchangeInfo")
    #|> IO.inspect()
  end

  def store_exchange_info do
    info = get_exchange_info()
    Enum.map(info["symbols"], fn x ->
      symbol = x["symbol"]
      {decimal, _} = Enum.find(x["filters"], fn f -> f["filterType"] == "LOT_SIZE" end)["stepSize"]
      |> Decimal.parse()

      lot_data = {symbol, decimal |> Decimal.normalize() }
      :ets.insert(:lot_size_lookup, lot_data)
    end)
  end

  def get_exchange_info_symbol(symbol) do
    info = get_exchange_info()
    Enum.find(info["symbols"], fn x -> x["symbol"] == symbol <> "USDT" end)
  end

  def get_lot_step_size(symbol) do
    [{_symbol, lot_size}] = :ets.lookup(:lot_size_lookup, symbol)
    lot_size
  end

  def sell_all(symbol) do
    IO.inspect("SELL ALL " <> symbol)
    bal = get_account_balance(symbol)
    |> IO.inspect()
    lot_size = get_lot_step_size(symbol <> "USDT")
    |> IO.inspect()
    %Decimal{ exp: exponent } = lot_size

    e = case exponent > 0 do
          true -> 0
          false -> exponent * -1
        end
      |> IO.inspect()

    query = "symbol=" <> symbol <> "USDT&newOrderRespType=FULL&side=SELL&type=MARKET&quantity=" <> Decimal.to_string(Decimal.round(bal, e)) <> "&"

    url = if Application.get_env(:cmcscraper, :use_test_endpoints), do: "v3/order/test", else: "v3/order"
    resp = post_request_with_signature(url, query)
    case resp.status_code do
      200 ->
        %{"success" => true, "resp" => resp}
      _ ->
        %{"success" => false, "resp" => resp}
    end
  end

  def sell_algo_trade(trade = %Cmcscraper.Schemas.AlgoTrade{}) do
    IO.inspect("SELL ALGO " <> trade.symbol)
    # bal = get_account_balance(symbol)
    # |> IO.inspect()
    lot_size = get_lot_step_size(trade.symbol)
    %Decimal{exp: exponent } = lot_size

    e = case exponent > 0 do
          true -> 0
          false -> exponent * -1
        end
      |> IO.inspect()

    query = "symbol=" <> trade.symbol <> "&newOrderRespType=FULL&side=SELL&type=MARKET&quantity=" <> Decimal.to_string(Decimal.round(trade.volume, e)) <> "&"

    url = if Application.get_env(:cmcscraper, :use_test_endpoints), do: "v3/order/test", else: "v3/order"
    resp = post_request_with_signature(url, query)
    case resp.status_code do
      200 ->
        {:ok, Poison.decode!(resp.body) }
      _ ->
        {:err, resp}
    end
  end

  @spec buy(binary, binary | integer | Decimal.t()) ::
          {:err, atom | %{:status_code => any, optional(any) => any}}
          | {:ok, atom | %{:status_code => any, optional(any) => any}}
  def buy(symbol, volume) do
    IO.inspect("BUY ALGO " <> symbol)

    lot_size = get_lot_step_size(symbol)
    %Decimal{exp: exponent } = lot_size

    e = case exponent > 0 do
          true -> 0
          false -> exponent * -1
        end
      |> IO.inspect()

    query = "symbol=" <> symbol <> "&newOrderRespType=FULL&side=BUY&type=MARKET&quantity=" <> Decimal.to_string(Decimal.round(volume, e)) <> "&"

    url = if Application.get_env(:cmcscraper, :use_test_endpoints), do: "v3/order/test", else: "v3/order"
    resp = post_request_with_signature(url, query)
    case resp.status_code do
      200 ->
        {:ok, Poison.decode!(resp.body) }
      _ ->
        IO.inspect(resp)
        {:err, Poison.decode!(resp.body)}
    end
  end

  def get_ticker_prices do
    get_request("v3/ticker/price")
  end
end
