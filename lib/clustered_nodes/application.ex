defmodule ClusteredNodes.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Cachex.Spec

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []

    # pogo_opts = [
    #   name: ClusteredNodes.DistributedSupervisor,
    #   scope: :clustered_nodes,
    #   children: [{ClusteredNodes.PsqlListener, "psql-listener"}]
    # ]

    children = [
      ClusteredNodesWeb.Telemetry,
      ClusteredNodes.Repo,
      {DNSCluster, query: Application.get_env(:clustered_nodes, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ClusteredNodes.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ClusteredNodes.Finch},
      # Start a worker by calling: ClusteredNodes.Worker.start_link(arg)
      # {ClusteredNodes.Worker, arg},
      {Cluster.Supervisor, [topologies, [name: ClusteredNodes.ClusterSupervisor]]},

      ## Highlander
      {Highlander, {ClusteredNodes.PsqlListener, []}},

      ## Pogo
      # {Pogo.DynamicSupervisor, pogo_opts},
      # Start to serve requests, typically the last entry
      ClusteredNodesWeb.Endpoint
    ]

    Cachex.start(:persistence, [
      router: router(module: Cachex.Router.Ring, options: [
        monitor: true
      ])
    ])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ClusteredNodes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClusteredNodesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
