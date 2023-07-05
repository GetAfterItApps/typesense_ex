defmodule Typesense do
  @moduledoc """
  Starts the Config process as well as the Typesense Node worker pool
  """
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(Typesense, config)
  end

  @impl true
  def init(config) do
    nodes_config = [:nodes, :nearest_node]
    pool_config = Map.take(config, nodes_config)
    request_config = Map.drop(config, nodes_config)

    children = [
      {Typesense.Request, request_config},
      {Typesense.Pool, pool_config}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
