# LtsePoc

* 100k 100-byte messages per second (ignoring network for now since that will be ms order-of-magnitude)
* All messages must be processed in-order

Architecture Idea:
* Stock_FSM 
  - Partition by stock - single process for each stock that actually does the matching/transaction for the bids and holds state
  - The state machine is completely deterministic from a series of events. That means starting at an initial condition and knowledge of the subsequent events, the state at time t is fully known. This means there can be multiple fsm's of the same stock running at the same time giving a result, so that this has built in HA (not withstanding a bug in the FSM, which would take down all units). Would need to filter out repetitive results or just elect a master.
  - This is where things can fall apart if the single pid is not fast enough. First thing to bench in POC.

* Ingress:
   - looks for the registered process and sends the message to the inbox.
   - Need to also journal the transaction so maybe use GenStage/Flow

* Redundancy: Multiple levels here.
  - Kubernetes HA (or just deploy different VM's to multi-AZ)
  - Use libcluster to deploy multiple pods onto Kube (or just deploy onto the VM's).
  - Use swarm to deploy multiple Stock_FSM onto different pods (ring_hash + crdt). Can also consider ip multicast.
  - This is a multi-stage system
     - From request to request journal - this is straightforward synchronous call. Complexity in journaling system setup availability.
     - From request journal to transaction (which is also logged/journaled). Need to watch for edge-cases on distributed transactions, do we send then modify state after waiting for ack? Do we rely on probability and having multiple stock_fsm running ensuring the journal will get something? Both?

* Journaling
  - Completely ignoring the journaling issue for now. Possibly/probably kafka. Need to record all the bids/sells/transactions.

* Replay / Reload
  - Again, ignoring for now. This is a POC after all, but a pid crashes, we've lost the state and need to reload from a checkpoint, preferably without having to replay an entire day of events and being on the right journal counter.

* Return codes
  - Have no idea about suitable return values/codes.

POC Checkpoints:
1) Deploy onto Kubernetes
2) Verify that the ring hash kill/respawn actions work (no need for multiple fsm running)
3) Bench the stock_fsm for some hopefully reasonable values.
     - Results On a 2008 Core 2 Duo - 3.5 µs for each insert
                                    - 1.6 µs for each match - probably will take 5-10 to make a trade (depends on many variables)
       Which is much better than original estimate - the stock_fsm at 5e-6 => 200k qps for a single stock on a singleton
4) GenStage to read from a file of events -> parsed transactions
5) Journaling / replay / crash recovery actions.

Flow:
- A request comes in it is either buy/sell/short/stop a particular stock at a given number of units. Could use GenStage to do this and include journal/replication steps.
  1) Journal the request. Once it is journaled, a 200 can be sent that the order has been submitted. This is the official timestamp that is used from the webserver initial request that gets journaled (or could just use the time from the journal).
  2) Parse the request, look up the pid for the processor of stock X.
  3) Send msg to pid into mailbox. To use erlang's ordering mechanism guarantees, it has to be from one process to another. Which kind of sucks, but we can make it work with a single reader from journal -> single processor per stock. Otherwise, we have to do some ordering/buffering magic.

  Algorithm (More details in  LtsePoc.Exchange.Trade.BrokerWorker):
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
 4) Record some transaction for later verification / reconciliation
 5) Return/send a response?

# Notes
mix phx.gen.json Exchange Trade trades email:string:unique stock:integer volume:integer price:float

Sets up multiple nodes connected together and starts a worker. Worker can move around and restart on failure.
```
iex --name "foo1@127.0.0.1" -S mix run
iex --name "foo2@127.0.0.1" -S mix run
LtsePoc.Exchange.Trade.Example.start_worker('test') # two nodes are connected and can move the worker around on node failure
```

TODO: Swarm.join/2 + Swarm.multi_call/2 - to have multiple workers or just have them both read from the journal.
