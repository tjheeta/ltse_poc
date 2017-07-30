defmodule LtsePoc.ExchangeTest do
  use LtsePoc.DataCase

  alias LtsePoc.Exchange

  describe "trades" do
    alias LtsePoc.Exchange.Trade

    @valid_attrs %{email: "some email", price: 120.5, stock: 42, volume: 42}
    @update_attrs %{email: "some updated email", price: 456.7, stock: 43, volume: 43}
    @invalid_attrs %{email: nil, price: nil, stock: nil, volume: nil}

    def trade_fixture(attrs \\ %{}) do
      {:ok, trade} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Exchange.create_trade()

      trade
    end

    test "list_trades/0 returns all trades" do
      trade = trade_fixture()
      assert Exchange.list_trades() == [trade]
    end

    test "get_trade!/1 returns the trade with given id" do
      trade = trade_fixture()
      assert Exchange.get_trade!(trade.id) == trade
    end

    test "create_trade/1 with valid data creates a trade" do
      assert {:ok, %Trade{} = trade} = Exchange.create_trade(@valid_attrs)
      assert trade.email == "some email"
      assert trade.price == 120.5
      assert trade.stock == 42
      assert trade.volume == 42
    end

    test "create_trade/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Exchange.create_trade(@invalid_attrs)
    end

    test "update_trade/2 with valid data updates the trade" do
      trade = trade_fixture()
      assert {:ok, trade} = Exchange.update_trade(trade, @update_attrs)
      assert %Trade{} = trade
      assert trade.email == "some updated email"
      assert trade.price == 456.7
      assert trade.stock == 43
      assert trade.volume == 43
    end

    test "update_trade/2 with invalid data returns error changeset" do
      trade = trade_fixture()
      assert {:error, %Ecto.Changeset{}} = Exchange.update_trade(trade, @invalid_attrs)
      assert trade == Exchange.get_trade!(trade.id)
    end

    test "delete_trade/1 deletes the trade" do
      trade = trade_fixture()
      assert {:ok, %Trade{}} = Exchange.delete_trade(trade)
      assert_raise Ecto.NoResultsError, fn -> Exchange.get_trade!(trade.id) end
    end

    test "change_trade/1 returns a trade changeset" do
      trade = trade_fixture()
      assert %Ecto.Changeset{} = Exchange.change_trade(trade)
    end
  end
end
