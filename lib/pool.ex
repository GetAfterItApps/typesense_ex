defmodule Typesense.Pool do
  @moduledoc """
  Supervises a pool of Typesense Nodes

  The `Pool` supervisor hydrates a set of Typesense Nodes. Typesense
  nodes can provide their configuration and may be temporariy removed from the
  requestable pool of nodes if they become unresponsive.
  """
  use Supervisor
  alias __MODULE__
  alias Typesense.Node

  @typedoc """
  Configuration Params

  ## Fields

    * `nearest_node` - (optional) node configuration for geographically nearest node (for optimizing network latency) . Type: `Node.config`
    * `nodes` - List of Typesense Node Configurations. Type: `[Node.config]`
  """

  @type config_params ::
          %{
            optional(:nearest_node) => Node.config(),
            nodes: nodes
          }

  @typedoc "A list of Node Configurations"
  @type nodes_configs :: [Node.config()]

  @typedoc """
  Pool

  A List of Typesense Nodes. Type: `[Node.t()]`
  """
  @type nodes :: [Node.t()]
  @type t :: nodes

  @type error :: {:error, String.t()}
  @type node_errors :: {:node_errors, nodes}

  @callback next_node() :: {pid(), Node.t()}

  @spec start_link(config_params()) ::
          {:ok, {:supervisor.sup_flags(), [:supervisor.child_spec()]}} | :ignore
  def start_link(config) do
    Supervisor.start_link(Pool, to_nodes(config))
  end

  @impl true
  def init(nodes) do
    node_specs =
      nodes
      |> Enum.with_index()
      |> Enum.map(fn {node, index} ->
        Supervisor.child_spec({Node, node}, id: {Node, index})
      end)

    nodes_supervisor_spec = %{
      id: :typesense_nodes_supervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [node_specs, [strategy: :one_for_one]]}
    }

    children = [
      {Registry, name: NodeRegistry, keys: :unique},
      nodes_supervisor_spec
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @spec next_node() :: Node.t()
  def next_node do
    nodes = Registry.lookup(NodeRegistry, :nodes)
    nearest = Enum.find(nodes, fn {_pid, node} -> node.is_nearest end)

    if nearest do
      nearest
    else
      Enum.random(nodes)
    end
  end

  @spec to_nodes(config_params()) :: nodes
  defp to_nodes(%{nodes: node_configs, nearest_node: nearest_node}) do
    node_configs
    |> Enum.map(fn node ->
      node
      |> Map.merge(%{is_nearest: node == nearest_node})
      |> Node.new()
    end)
  end

  defp to_nodes(%{nodes: node_configs}) do
    node_configs |> Enum.map(&Node.new/1)
  end
end
