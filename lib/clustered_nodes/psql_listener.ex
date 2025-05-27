defmodule ClusteredNodes.PsqlListener do
  use GenServer

  require Logger

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Logger.info("starting psql listener")

    {:ok, pid} = Postgrex.Notifications.start_link(ClusteredNodes.Repo.config())
    {:ok, _ref} = Postgrex.Notifications.listen(pid, "test_channel")

    {:ok, %{counter: 0}}
  end

  @impl true
  def handle_info(message, state) do
    Logger.info("Received message: #{inspect(message)}, with state: #{inspect(state)}")

    ## update counte
    {:noreply, %{state | counter: state.counter + 1}}
  end
end
