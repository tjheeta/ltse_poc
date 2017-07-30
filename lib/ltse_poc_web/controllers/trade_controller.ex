defmodule LtsePocWeb.TradeController do
  use LtsePocWeb, :controller

  alias LtsePoc.Exchange
  alias LtsePoc.Exchange.Trade

  def index(conn, _params) do
    #trades = Exchange.list_trades()
    #render(conn, "index.html", trades: trades)
    render(conn, "index.html", trades: [])
  end

  def new(conn, _params) do
    changeset = Exchange.change_trade(%Trade{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"trade" => trade_params}) do
    case Exchange.create_trade(trade_params) do
      {:ok, trade} ->
        conn
        |> put_flash(:info, "Trade created successfully.")
        |> redirect(to: trade_path(conn, :show, trade))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    trade = Exchange.get_trade!(id)
    render(conn, "show.html", trade: trade)
  end

  def edit(conn, %{"id" => id}) do
    trade = Exchange.get_trade!(id)
    changeset = Exchange.change_trade(trade)
    render(conn, "edit.html", trade: trade, changeset: changeset)
  end

  def update(conn, %{"id" => id, "trade" => trade_params}) do
    trade = Exchange.get_trade!(id)

    case Exchange.update_trade(trade, trade_params) do
      {:ok, trade} ->
        conn
        |> put_flash(:info, "Trade updated successfully.")
        |> redirect(to: trade_path(conn, :show, trade))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", trade: trade, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    trade = Exchange.get_trade!(id)
    {:ok, _trade} = Exchange.delete_trade(trade)

    conn
    |> put_flash(:info, "Trade deleted successfully.")
    |> redirect(to: trade_path(conn, :index))
  end
end
