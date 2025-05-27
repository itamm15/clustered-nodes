defmodule ClusteredNodes.Repo do
  use Ecto.Repo,
    otp_app: :clustered_nodes,
    adapter: Ecto.Adapters.Postgres
end
