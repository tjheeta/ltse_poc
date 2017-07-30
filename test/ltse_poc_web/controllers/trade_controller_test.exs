defmodule LtsePocWeb.TradeControllerTest do
  use LtsePocWeb.ConnCase

  alias LtsePoc.Exchange

  @create_attrs %{email: "some email", price: 120.5, stock: 42, volume: 42}
  @update_attrs %{email: "some updated email", price: 456.7, stock: 43, volume: 43}
  @invalid_attrs %{email: nil, price: nil, stock: nil, volume: nil}

  def fixture(:trade) do
    {:ok, trade} = Exchange.create_trade(@create_attrs)
    trade
  end

  describe "index" do
    test "lists all trades", %{conn: conn} do
      conn = get conn, trade_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Trades"
    end
  end

  describe "new trade" do
    test "renders form", %{conn: conn} do
      conn = get conn, trade_path(conn, :new)
      assert html_response(conn, 200) =~ "New Trade"
    end
  end

  describe "create trade" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, trade_path(conn, :create), trade: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == trade_path(conn, :show, id)

      conn = get conn, trade_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Trade"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, trade_path(conn, :create), trade: @invalid_attrs
      assert html_response(conn, 200) =~ "New Trade"
    end
  end

  describe "edit trade" do
    setup [:create_trade]

    test "renders form for editing chosen trade", %{conn: conn, trade: trade} do
      conn = get conn, trade_path(conn, :edit, trade)
      assert html_response(conn, 200) =~ "Edit Trade"
    end
  end

  describe "update trade" do
    setup [:create_trade]

    test "redirects when data is valid", %{conn: conn, trade: trade} do
      conn = put conn, trade_path(conn, :update, trade), trade: @update_attrs
      assert redirected_to(conn) == trade_path(conn, :show, trade)

      conn = get conn, trade_path(conn, :show, trade)
      assert html_response(conn, 200) =~ "some updated email"
    end

    test "renders errors when data is invalid", %{conn: conn, trade: trade} do
      conn = put conn, trade_path(conn, :update, trade), trade: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Trade"
    end
  end

  describe "delete trade" do
    setup [:create_trade]

    test "deletes chosen trade", %{conn: conn, trade: trade} do
      conn = delete conn, trade_path(conn, :delete, trade)
      assert redirected_to(conn) == trade_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, trade_path(conn, :show, trade)
      end
    end
  end

  defp create_trade(_) do
    trade = fixture(:trade)
    {:ok, trade: trade}
  end
end
