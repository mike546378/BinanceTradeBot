defmodule Cmcscraper.Helpers.PortfolioHelper do

  alias Cmcscraper.Schemas.Portfolio
  alias Cmcscraper.RepoFunctions.PortfolioRepository

  def sync_binance(_slug, balance, ticker_data, _portfolio_record, _currency) when is_nil(ticker_data) and balance == 0 do
    nil
  end

  def sync_binance(slug, _balance, ticker_data, _portfolio_record, _currency) when is_nil(ticker_data) do
    %{error: :trade_pair_not_found, slug: slug}
  end

  def sync_binance(slug, balance, ticker_data, _portfolio_record, currency) when is_nil(currency) and is_number(balance) do
      current_price = String.to_float(ticker_data["price"])
      if balance * current_price < 10 do
        nil
      else
        %{error: :currency_slug_not_found, slug: slug}
      end
  end

  def sync_binance(slug, _balance, _ticker_data, _portfolio_record, currency) when is_nil(currency) do
      %{error: :currency_slug_not_found, slug: slug}
  end

  def sync_binance(slug, balance, ticker_data, portfolio_record, currency)
  when
    is_nil(portfolio_record)
    and is_number(balance)
  do
    if balance > 0 do
      current_price = String.to_float(ticker_data["price"])
      if current_price * balance > 10 do
        {:ok, resp} = PortfolioRepository.insert_trade(currency.id, balance, current_price)
        Portfolio.to_dto(resp)
      else
        %{error: :balance_too_low, slug: slug}
      end
    end
  end

  def sync_binance(slug, balance, ticker_data, %Portfolio{} = portfolio_record, _currency) when is_number(balance) do
    current_price = String.to_float(ticker_data["price"])
    cond do
      balance * current_price < 10 ->
        PortfolioRepository.delete_portfolio(portfolio_record.id)
        %{error: :removed_low_balance, slug: slug}
      portfolio_record.volume != balance ->
        {:ok, resp} = PortfolioRepository.add_update_portfolio(%Portfolio{portfolio_record | volume: balance})
        Portfolio.to_dto(resp)
      true ->
        Portfolio.to_dto(portfolio_record)
    end
  end

end
