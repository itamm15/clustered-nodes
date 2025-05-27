# ClusteredNodes

## Libcluster, without any node leadership 

Node1
```elixir
clustered_nodes % iex --sname node1 -S mix phx.server
Erlang/OTP 27 [erts-15.0.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Compiling 1 file (.ex)
[info] starting psql listener
[info] Running ClusteredNodesWeb.Endpoint with Bandit 1.6.11 at 127.0.0.1:4000 (http)
[info] Access ClusteredNodesWeb.Endpoint at http://localhost:4000
Interactive Elixir (1.17.2) - press Ctrl+C to exit (type h() ENTER for help)
[watch] build finished, watching for changes...

Rebuilding...

Done in 136ms.
[info] [libcluster:local_gossip] connected to :"node2@Mateuszs-MacBook-Pro-2"
[info] global: Name conflict terminating {Swoosh.Adapters.Local.Storage.Memory, #PID<27138.272.0>}

[info] Received message: {:notification, #PID<0.332.0>, #Reference<0.2783425453.1933836289.150861>, "test_channel", "test"}, with state: %{counter: 0}
[info] Received message: {:notification, #PID<0.332.0>, #Reference<0.2783425453.1933836289.150861>, "test_channel", "test"}, with state: %{counter: 1}
iex(node1@Mateuszs-MacBook-Pro-2)1>
```

Node2
```elixir
Erlang/OTP 27 [erts-15.0.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

[info] starting psql listener
[info] Running ClusteredNodesWeb.Endpoint with Bandit 1.6.11 at 127.0.0.1:4001 (http)
[info] Access ClusteredNodesWeb.Endpoint at http://localhost:4001
Interactive Elixir (1.17.2) - press Ctrl+C to exit (type h() ENTER for help)
[watch] build finished, watching for changes...

Rebuilding...

Done in 138ms.
[info] Received message: {:notification, #PID<0.318.0>, #Reference<0.2491773757.3812884481.62156>, "test_channel", "test"}, with state: %{counter: 0}
[info] Received message: {:notification, #PID<0.318.0>, #Reference<0.2491773757.3812884481.62156>, "test_channel", "test"}, with state: %{counter: 1}
iex(node2@Mateuszs-MacBook-Pro-2)1> 
```

Both nodes receive messages per psql broadcast; 

```psql
mateuszosinski=# \c clustered_nodes_dev 
psql (14.13 (Homebrew), server 15.0)
WARNING: psql major version 14, server major version 15.
         Some psql features might not work.
You are now connected to database "clustered_nodes_dev" as user "mateuszosinski".
clustered_nodes_dev=# NOTIFY test_channel, 'test';
NOTIFY
clustered_nodes_dev=# NOTIFY test_channel, 'test';
NOTIFY
clustered_nodes_dev=# 
```


## With Highlander

Outcome: `Node2` takes the leadership over the `PsqlListener`. In case of failover, the `Node1` is taking the leadership over the `PsqlListener`, with init state.

In `application.ex`

```elixir
{Highlander, {ClusteredNodes.PsqlListener, []}},
```

Node1
```elixir
clustered_nodes % iex --sname node1 -S mix phx.server
Erlang/OTP 27 [erts-15.0.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

[debug] Starting Highlander with ClusteredNodes.PsqlListener as uniqueness key
[info] starting psql listener
[info] Running ClusteredNodesWeb.Endpoint with Bandit 1.6.11 at 127.0.0.1:4000 (http)
[info] Access ClusteredNodesWeb.Endpoint at http://localhost:4000
Interactive Elixir (1.17.2) - press Ctrl+C to exit (type h() ENTER for help)
[watch] build finished, watching for changes...

Rebuilding...

Done in 147ms.
[info] [libcluster:local_gossip] connected to :"node2@Mateuszs-MacBook-Pro-2"
[info] global: Name conflict terminating {Swoosh.Adapters.Local.Storage.Memory, #PID<27007.272.0>}

iex(node1@Mateuszs-MacBook-Pro-2)1> 
```

Node2
```elixir
clustered_nodes % iex --sname node2 -S mix phx.server
Erlang/OTP 27 [erts-15.0.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

[debug] Starting Highlander with ClusteredNodes.PsqlListener as uniqueness key
[info] starting psql listener
[info] Running ClusteredNodesWeb.Endpoint with Bandit 1.6.11 at 127.0.0.1:4001 (http)
[info] Access ClusteredNodesWeb.Endpoint at http://localhost:4001
Interactive Elixir (1.17.2) - press Ctrl+C to exit (type h() ENTER for help)
[watch] build finished, watching for changes...

Rebuilding...

Done in 160ms.
[info] Received message: {:notification, #PID<0.319.0>, #Reference<0.3386486655.1405353986.43614>, "test_channel", "test"}, with state: %{counter: 0}
[info] Received message: {:notification, #PID<0.319.0>, #Reference<0.3386486655.1405353986.43614>, "test_channel", "test"}, with state: %{counter: 1}
iex(node2@Mateuszs-MacBook-Pro-2)1
```

Node2 failure: 

Node1
```elixir
[info] starting psql listener
[info] Received message: {:notification, #PID<0.656.0>, #Reference<0.2330458113.4090232835.239167>, "test_channel", "test"}, with state: %{counter: 0}
iex(node1@Mateuszs-MacBook-Pro-2)1> 
```


## With Pogo

The outcome of Pogo is the same as the outcome of Highlander.


## Persist the state

To persist the GenServer's state across nodes in the cluster we need `Cachex` with clustered routers. 

In `application.ex`

```elixir
  Cachex.start(:persistence, [
    router: router(module: Cachex.Router.Ring, options: [
      monitor: true
    ])
  ])
```

Node1
```elixir
clustered_nodes % iex --sname node1 -S mix phx.server
Erlang/OTP 27 [erts-15.0.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Compiling 1 file (.ex)
[debug] Starting Highlander with ClusteredNodes.PsqlListener as uniqueness key
[info] starting psql listener
[info] Running ClusteredNodesWeb.Endpoint with Bandit 1.6.11 at 127.0.0.1:4000 (http)
[info] Access ClusteredNodesWeb.Endpoint at http://localhost:4000
Interactive Elixir (1.17.2) - press Ctrl+C to exit (type h() ENTER for help)
[watch] build finished, watching for changes...

Rebuilding...

Done in 145ms.
[info] [libcluster:local_gossip] connected to :"node2@Mateuszs-MacBook-Pro-2"
[info] global: Name conflict terminating {Swoosh.Adapters.Local.Storage.Memory, #PID<27555.273.0>}

iex(node1@Mateuszs-MacBook-Pro-2)1> 
```

Node2
```elixir
clustered_nodes % iex --sname node2 -S mix phx.server
Erlang/OTP 27 [erts-15.0.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

[debug] Starting Highlander with ClusteredNodes.PsqlListener as uniqueness key
[info] starting psql listener
[info] Running ClusteredNodesWeb.Endpoint with Bandit 1.6.11 at 127.0.0.1:4001 (http)
[info] Access ClusteredNodesWeb.Endpoint at http://localhost:4001
Interactive Elixir (1.17.2) - press Ctrl+C to exit (type h() ENTER for help)
[watch] build finished, watching for changes...

Rebuilding...

Done in 153ms.
[info] Received message: {:notification, #PID<0.347.0>, #Reference<0.3506071623.1964244995.72878>, "test_channel", "test"}, with state: %{counter: 0}
[info] Received message: {:notification, #PID<0.347.0>, #Reference<0.3506071623.1964244995.72878>, "test_channel", "test"}, with state: %{counter: 1}
[info] Received message: {:notification, #PID<0.347.0>, #Reference<0.3506071623.1964244995.72878>, "test_channel", "test"}, with state: %{counter: 2}
iex(node2@Mateuszs-MacBook-Pro-2)1> 
```

`Node2` failure:

Node1
```elixir
[info] starting psql listener
[info] Received message: {:notification, #PID<0.703.0>, #Reference<0.2976068672.1427111937.222463>, "test_channel", "test"}, with state: %{counter: 3}
[info] Received message: {:notification, #PID<0.703.0>, #Reference<0.2976068672.1427111937.222463>, "test_channel", "test"}, with state: %{counter: 4}
iex(node1@Mateuszs-MacBook-Pro-2)1> 
```