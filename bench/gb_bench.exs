# bench/gb_bench.exs
defmodule GbBench do
  use Benchfella

  #  @list_size = 100
  #@price_size = 10000
  #@list Enum.to_list(1..list_size)
  #@prices Enum.map(1..price_size, &(:rand.uniform(1000)))

  @list_size 1
  @price_size 100000
  @list Enum.to_list(1..@list_size)
  @prices Enum.map(1..@price_size, fn(x) -> :rand.uniform(1000000) end)

  bench "gb insert" do
    volume = 100
    Enum.reduce(@list, :gb_trees.empty(), fn(id, tree) ->
      Enum.reduce(@prices, tree, fn(price, tree) ->
         LtsePoc.Exchange.Trade.BrokerWorker.insert_bids_buy({id, price, volume}, tree)
      end)
   end)
  end
end
