defmodule Cmcscraper.RepoFunctions.PortfolioRepository do
  import Ecto.Query
  alias Cmcscraper.Repo
  alias Cmcscraper.Schemas.Portfolio
  alias Cmcscraper.Schemas.Currency

  def insert_trade(currency_id, volume, purchase_price), do: insert_trade(currency_id, volume, purchase_price, 10)
  def insert_trade(currency_id, volume, purchase_price, percentage) do
    Portfolio.changeset(%Portfolio{}, %{currency_id: currency_id, volume: volume, purchase_price: purchase_price, peak_price: purchase_price, purchase_date: DateTime.utc_now(), percentage_change_requirement: percentage})
    |> Repo.insert()
  end

  def remove_trade(currency_id) do
    q = from p in Portfolio, where: [currency_id: ^currency_id]
    Repo.delete_all(q)
  end

  def add_update_portfolio(%Portfolio{} = portfolio) when is_nil(portfolio.id) do
    Portfolio.changeset(%Portfolio{}, Map.from_struct(portfolio))
    |> Repo.insert_or_update()
  end

  def add_update_portfolio(%Portfolio{} = portfolio) do
    case Repo.one from p in Portfolio, where: [id: ^portfolio.id], limit: 1 do
      %Portfolio{} = p ->
        Portfolio.changeset(p, Map.from_struct(portfolio))
      nil ->
        Portfolio.changeset(%Portfolio{}, Map.from_struct(portfolio))
    end
    |> Repo.insert_or_update()
  end

    def sell_trade(portfolio_id, price) when is_integer(price) do
      {:ok, dec_price} = Decimal.cast(price)
      sell_trade(portfolio_id, dec_price)
    end

    def sell_trade(portfolio_id, price) when is_float(price) do
      {:ok, dec_price} = Decimal.cast(price)
      sell_trade(portfolio_id, dec_price)
    end

    def sell_trade(portfolio_id, price) do
    case Repo.one from p in Portfolio, where: [id: ^portfolio_id], limit: 1 do
      %Portfolio{} = p ->
        profit = Decimal.sub(price, p.purchase_price) |> Decimal.mult(p.volume)
        record = %Portfolio{ p | sell_date: DateTime.utc_now(), sell_price: price, profit: profit}
        Portfolio.changeset(p, Map.from_struct(record))
        |> Repo.insert_or_update()
      nil ->
        nil
    end
  end

  def get_active_trades() do
      (
        from p in Portfolio,
        join: c in Currency,
          on: c.id == p.currency_id,
        where: is_nil(p.sell_date),
        preload: [currency: c]
      )
      |> Repo.all()
  end

  def get_all_trades() do
    (
      from p in Portfolio,
      join: c in Currency,
        on: c.id == p.currency_id,
      preload: [currency: c]
    )
    |> Repo.all()
  end
end
