defmodule LtsePoc.BrokerWorkerTest do
  use LtsePoc.DataCase

  alias LtsePoc.Exchange
  alias LtsePoc.Exchange.Trade.BrokerWorker

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

    def buy_state_tree_fixture(attrs \\ %{}) do
      list_size = attrs['list_size']
      price_size = attrs['price_size']
      list = Enum.to_list(1..list_size)
      prices = Enum.map(1..@price_size, fn(x) -> :rand.uniform(1000000) end)

      volume = attrs['volume']
      Enum.reduce(@list, :gb_trees.empty(), fn(id, tree) ->
        Enum.reduce(@prices, tree, fn(price, tree) ->
         LtsePoc.Exchange.Trade.BrokerWorker.insert_bids_buy({id, price, volume}, tree)
        end)
      end)
    end

    def buy_state_fixture( array) do
      Enum.reduce(array, :gb_trees.empty(), fn({sell_id, price, volume}, tree) ->
         LtsePoc.Exchange.Trade.BrokerWorker.insert_bids_buy({sell_id, price, volume}, tree)
      end)
    end

    test "basic find buyer" do
      state_tree_buys = buy_state_fixture(
        [ { 1, 10, 100 }, { 2, 5, 1000}, { 3, 20, 50 } ]
      )
      iter = :gb_trees.iterator_from(17, state_tree_buys)
      {volume_left, transactions, state_tree_buys_new} = LtsePoc.Exchange.Trade.BrokerWorker.find_buyer_tree_iter({100001, 20, 50}, [], state_tree_buys, iter)
      assert volume_left == 0
      assert :gb_trees.keys(state_tree_buys_new) == [5,10]
      assert transactions = {1,100001,20, 50}
    end

    test "complex find buyer 1" do
      state_tree_buys = buy_state_fixture(
        [ { 1, 10, 100 }, { 2, 5, 1000}, { 3, 20, 50 } ]
      )
      iter = :gb_trees.iterator_from(4, state_tree_buys)
      {volume_left, transactions, state_tree_buys_new} = LtsePoc.Exchange.Trade.BrokerWorker.find_buyer_tree_iter({100001, 3.5, 100000}, [], state_tree_buys, iter)
      assert transactions = [{100001, 1, 3.5 ,100 }, {100001, 2, 3.5, 1000}, {100001, 3, 3.5, 50}]
      assert :gb_trees.keys(state_tree_buys_new) == []
      assert volume_left == (100000 - 100 - 1000 - 50)
    end

    test "complex find buyer 2" do
      state_tree_buys = buy_state_fixture(
        [ { 1, 10, 100 }, { 2, 5, 1000}, { 3, 20, 50 } ]
      )
      iter = :gb_trees.iterator_from(4, state_tree_buys)
      {volume_left, transactions, state_tree_buys_new} = LtsePoc.Exchange.Trade.BrokerWorker.find_buyer_tree_iter({100001, 3.5, 1125}, [], state_tree_buys, iter)
      assert transactions = [{100001, 1, 3.5 ,100 }, {100001, 2, 3.5, 1000}, {100001, 3, 3.5, 50}]
      assert :gb_trees.keys(state_tree_buys_new) == [20]
      assert :gb_trees.lookup(20, state_tree_buys_new) == {:value, [ {3, 25 } ]}
      assert volume_left == 0
    end
  end
end
