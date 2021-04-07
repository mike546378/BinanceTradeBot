defmodule Cmcscraper.Helpers.BinanceApiHelper do

  def get_request(endpoint), do: get_request(endpoint, "")
  def get_request(endpoint, query) do
    api_key = Application.get_env(:cmcscraper, :binance_api_key)
    base_url = Application.get_env(:cmcscraper, :binance_api_uri)

    response = HTTPoison.get!(base_url <> endpoint <> "?" <> query, [{"X-MBX-APIKEY", api_key}])
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
    response = HTTPoison.get!(base_url <> endpoint <> "?" <> body, [{"X-MBX-APIKEY", api_key}])
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
    HTTPoison.post!(base_url <> endpoint <> "?" <> body, "", [{"X-MBX-APIKEY", api_key}])
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
    get_request("v3/exchangeInfo")
  end

  def get_exchange_info_symbol(symbol) do
    info = get_exchange_info()
    Enum.find(info["symbols"], fn x -> x["symbol"] == symbol <> "USDT" end)
  end

  def get_lot_step_size(symbol) do
    info = get_exchange_info_symbol(symbol)
    Enum.find(info["filters"], fn x -> x["filterType"] == "LOT_SIZE" end)["stepSize"]
    |> String.to_float()
  end

  def sell_all(symbol) do
    bal = get_account_balance(symbol)
    |> IO.inspect()
    lot_size = get_lot_step_size(symbol)
    |> IO.inspect()
    %Decimal{exp: exponent } = Decimal.from_float(lot_size)

    e = case exponent > 0 do
          true -> 0
          false -> exponent * -1
        end
      |> IO.inspect()

    query = "symbol=" <> symbol <> "USDT&side=SELL&type=MARKET&quantity=" <> Float.to_string(Float.floor(bal, e)) <> "&"
    resp = post_request_with_signature("v3/order", query)
    case resp.status_code do
      200 ->
        %{"success" => true}
      _ ->
        %{"success" => false, "resp" => resp}
    end
  end

  def get_ticker_prices do
    get_request("v3/ticker/price")
  end
end
