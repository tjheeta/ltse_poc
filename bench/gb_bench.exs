# bench/gb_bench.exs
defmodule GbBench do
  use Benchfella

  #  @list_size = 100
  #@price_size = 10000
  #@list Enum.to_list(1..list_size)
  #@prices Enum.map(1..price_size, &(:rand.uniform(1000)))

  @list_size 5
  @price_size 100000
  #@list_size 10
  #@price_size 100
  @list Enum.to_list(1..@list_size)
  @prices Enum.map(1..@price_size, fn(x) -> :rand.uniform(1000000) end)
  @volume  100
  @state_buy Enum.reduce(@list, :gb_trees.empty(), fn(id, tree) ->
               Enum.reduce(@prices, tree, fn(price, tree) ->
                 LtsePoc.Exchange.Trade.BrokerWorker.insert_bids_buy({id, price, @volume}, tree)
               end)
             end)

  # gb insert (core 2 duo)  1831842.00 µs/op => 1831842 / 500000 = 3.66 µs per elements
  # gb insert (aws)   1137797.00 µs/op => 1137797.00 / 500000 = 2.27 µs per elements
  bench "gb insert" do
    Enum.reduce(@list, :gb_trees.empty(), fn(id, tree) ->
      Enum.reduce(@prices, tree, fn(price, tree) ->
         LtsePoc.Exchange.Trade.BrokerWorker.insert_bids_buy({id, price, @volume}, tree)
      end)
    end)
  end

  # gb search (aws)          search        10000000   0.64 µs/op
  bench "search" do 
    iter = :gb_trees.iterator_from(4, @state_buy)
    # (core 2 duo)  search         1000000   1.61 µs/op
    # (core 2 duo)  search         1000000   2.18 µs/op
    # aws           search        10000000   0.84 µs/op
    # aws           search        10000000   0.64 µs/op
    # aws           search        10000000   1.27 µs/op
    {volume_left, transactions, state_tree_buys_new} = LtsePoc.Exchange.Trade.BrokerWorker.find_buyer_tree_iter({100001, 3.5, 100}, [], @state_buy, iter) 

    # (core 2 duo) search           50000   35.06 µs/op
    # (aws)        search          100000   15.14 µs/op
    #{volume_left, transactions, state_tree_buys_new} = LtsePoc.Exchange.Trade.BrokerWorker.find_buyer_tree_iter({100001, 3.5, 10000}, [], @state_buy, iter) 

    # (core 2 duo ) search           10000   273.70 µs/op - 10x more, makes sense should be linear as asking for more volume
    # aws           search           10000   167.91 µs/op
    # aws           search           10000   191.01 µs/op
    #{volume_left, transactions, state_tree_buys_new} = LtsePoc.Exchange.Trade.BrokerWorker.find_buyer_tree_iter({100001, 3.5, 100000}, [], @state_buy, iter) 
    #IO.inspect length(transactions)
  end


  #tmp = Enum.reduce(Enum.to_list(1..10), :gb_trees.empty(), fn(id, tree) -> Enum.reduce( Enum.map(1..100000, fn(x) -> :rand.uniform(1000000) end), tree, fn(price, tree) -> LtsePoc.Exchange.Trade.BrokerWorker.insert_bids_buy({id, price, 100}, tree) end) end)
  #iter = :gb_trees.iterator_from(3.5, tmp)
  #  {v,t,s} = LtsePoc.Exchange.Trade.BrokerWorker.find_buyer_tree_iter({100001, 3.5, 1125}, [], tmp, iter)
end

