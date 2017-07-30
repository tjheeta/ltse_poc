defmodule LtsePoc.Exchange.Trade.BrokerWorker do
  @moduledoc """
  This is the worker process for a given stock. This will be a singleton to avoid any race conditions or moving to a locking structure for transactions outside of the beam vm. Trying to do everything in memory.
  We can probably do some optimization with multiple processes by separating read/write/buy/sell. Before any optimization, the naive implementation needs to be benchmarked. 

  Algorithm:
  - If req == sell
    Match against existing list of buys
      check the min(price) in buys that is >= than sell price ordered by t
      True -> remove buy -> send trade
      False -> insert into sell table (sorted set)
  - If req == buy
    Match against existing list of sells
      check the max(price) in sells that is <= than buy price ordered by t
      True -> remove sell -> send trade
      False -> 
        insert into buy table (sorted set)

  Can match and insert happen concurrently? Not sure if this makes sense. The whole point is to do the matching on existing orders first, then insert? Algorithm would have to change to do:
  - insert?
  - msg
  - compare all?

  Need an appropriate data structure to do matching: 
  [price, [ list of asks ordered by t (t, volume, uid) ]
  # skip on uid and any other potential information for now
  {
  110.3 => [ (t1, 100), (t2, 10) ]
  109 => [ (t3, 100), (t4, 10) ]
  }
  Possibly two ets tables: buys_x, sells_x where x = name which is the stock_id
    - the key would need to be sorted, so not sure if ets is a good fit. 
    - not going to be reading from other processes for now either, so no point

  ASSUMPTION:
  1) Trying to optimize for the most volume buy ordering the sells by lowest buying price instead of initial order time.
  2) Otherwise, the data structure is much simply ordered by time, we have to iterate over time first, then find if the prices correspond.
  3) Or we have to find all prices that match and then order by time.
  1 = O(n) - over smaller price range
  2 = O(n)+ - over all possible bids
  3 = O(nlgn) - this involves a time sort

  Probably best data structure to use is either:
  Red-black trees - https://github.com/rvirding/rb/
  General-balanced trees - http://erlang.org/doc/man/gb_trees.html

  Given the assumption above then:
  key is price, the value is {time, volume}  (although we are using a linked list traversal sorted by time anyway)
  {
    p1 => [{t,v} , {t2,v2}]
    p2 => [{tn,vn} , {t_n1,v_n1}]
  }
  t = :gb_trees.empty()
  t = :gb_trees.insert(10, [{2, 10}], t)
  t = :gb_trees.insert(9, [{1, 10}], t)
  t = :gb_trees.insert(10.2, [{1, 10}], t)
  t = :gb_trees.insert(10.1, [{1, 10}], t)

  :gb_trees.keys(t)
  [9, 10, 10.1, 10.2]

  s = :gb_trees.iterator_from(10.05, t)
  [{10.1, [{1, 10}], nil, nil},
   {10.2, [{1, 10}], {10.1, [{1, 10}], nil, nil}, nil}]
   {x1,v1, s1} = :gb_trees.next(s)
   # x1 = 10.1 # key
   # v1 = [ {1,10} ] # value
   # s1 = # next iterator
   #  = [{10.2, [{1, 10}], {10.1, [{1, 10}], nil, nil}, nil}]

  Some other useful functions from gb_trees:
  %% - enter(X, V, T): inserts key X with value V into tree T if the key
  %%   is not present in the tree, otherwise updates key X to value V in
  %%   T. Returns the new tree.
  %% - iterator_from(K, T): returns an iterator that can be used for
  %%   traversing the entries of tree T with key greater than or
  %%   equal to K; see `next'.
  %% - next(S): returns {X, V, S1} where X is the smallest key referred to
  %%   by the iterator S, and S1 is the new iterator to be used for
  %%   traversing the remaining entries, or the atom `none' if no entries
  %%   remain.

  Note that only iterator_from is implemented (goes from least to greater).
  So we'll only implement the full matching for a sell that comes in.

  Pseudocode:
  # this doesn't need to be completely right, we just need an offhand benchmark
  def handle_call({:sell, {t, price, volume}, _from, {stock_name, state_tree_buys, state_tree_sells} ) do
    iter = :gb_trees.iterator_from(price, state_tree_buys)
    {price_buy, array_transact_buys, iter} = :gb_trees.next(iter)
    # need to remove/subtract any transactions that fit and send a msg off (yuck, but can reconcile/replay later)
    # need a custom reducer here as Enum.reduce doesn't like the iterator

    # forall p where prices > price
    #   get the bids
    #   while [{_,v} | t ] do
    #     # a couple of cases here
    #     # cond 
    #         volume < v -> send msg to book the transaction, update state_tree_buys key with the subtracted volume + tail, stop
    #         volume > v -> send msg to book the transaction and keep iterating
    #         no bids left -> append to state_tree_sells, do we want to remove the key from state_tree_buys?
    #     # end
    #   end
    
    {:reply, {:processed}, {name, state_tree_buys, state_tree_sells}}
  end

  # just insert into the state tree
  def handle_call({:buy, {t, price, volume}, _from, {stock_name, state_tree_buys, state_tree_sells} ) do
    # fetch the key and then update the list
    {:reply, {:no_transaction, 0}, {stock_name, state_tree_buys, state_tree_sells}}
  end

  ## quick benchmark
  Inserts:
  On Core 2 Duo - 100k inserts of random prices between 1-1e6 is 0.35 seconds into gb_tree


  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, [name])
  end

  def init([name]) do
    # returns ok, state, timeout
    # also probably should stream from the event source to replay. 
    # but hey, still need a base benchmark 
    state_tree_buys = :gb_trees.empty()
    state_tree_sells = :gb_trees.empty()
    {:ok, {name, state_tree_buys, state_tree_sells}, 0}
  end

  # called when a handoff has been initiated due to changes
  # in cluster topology, valid response values are:
  #
  #   - `:restart`, to simply restart the process on the new node
  #   - `{:resume, state}`, to hand off some state to the new process
  #   - `:ignore`, to leave the process running on it's current node
  #
  def handle_call({:swarm, :begin_handoff}, _from, {name, delay}) do
    {:reply, {:resume, delay}, {name, delay}}
  end
  # called after the process has been restarted on it's new node,
  # and the old process's state is being handed off. This is only
  # sent if the return to `begin_handoff` was `{:resume, state}`.
  # **NOTE**: This is called *after* the process is successfully started,
  # so make sure to design your processes around this caveat if you
  # wish to hand off state like this.
  def handle_cast({:swarm, :end_handoff, delay}, {name, _}) do
    {:noreply, {name, delay}}
  end
  # called when a network split is healed and the local process
  # should continue running, but a duplicate process on the other
  # side of the split is handing off it's state to us. You can choose
  # to ignore the handoff state, or apply your own conflict resolution
  # strategy
  def handle_cast({:swarm, :resolve_conflict, _delay}, state) do
    {:noreply, state}
  end

  def handle_info(:timeout, {name, delay}) do
    IO.puts "#{inspect name} says hi! #{delay}"
    Process.send_after(self(), :timeout, delay)
    {:noreply, {name, delay}}
  end
  # this message is sent when this process should die
  # because it's being moved, use this as an opportunity
  # to clean up
  def handle_info({:swarm, :die}, state) do
    {:stop, :shutdown, state}
  end

  # returns the new state tree 
  # TODO - array_of_bids is is appending on cons cell instead of prepending.
  # This is bad for performance as elixir has no damn tail pointer.
  def insert_bids_buy({id,price,volume}, state_tree_buys) do
    case :gb_trees.lookup(price, state_tree_buys) do
      :none -> :gb_trees.insert(price, [{id, volume}], state_tree_buys)
      {:value, array_of_bids} -> :gb_trees.update( price,
                                    array_of_bids ++ [{id, volume}],
                                    state_tree_buys
                                    )
    end
  end
end
