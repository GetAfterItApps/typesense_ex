defmodule TypesenseEx.Pool do
  @moduledoc """
  Supervises a pool of Typesense Nodes

  The `Pool` supervisor hydrates a set of Typesense Nodes. Typesense
  nodes can provide their configuration and may be temporariy removed from the
  requestable pool of nodes if they become unresponsive.
  """
  use Supervisor
  alias __MODULE__
  alias TypesenseEx.Node

  @typedoc "Whether or not a validation has failed"
  @type validation_response :: :ok | {:error, String.t()}
  @typedoc "A list of Node Configurations"
  @type nodes :: [Node.config()]

  @typedoc """
  Configuration Params

  ## Fields

    * `nearest_node` - (optional) node configuration for geographically nearest node (for optimizing network latency) . Type: `Node.config`
    * `nodes` - List of TypesenseEx Node Configurations. Type: `[Node.config]`
  """

  @type config_params ::
          %{
            optional(:nearest_node) => Node.config(),
            nodes: nodes
          }

  @typedoc """
  Pool

  ## Fields

    * `nearest_node` - (optional) node configuration for geographically nearest node (for optimizing network latency) . Type: `Node.config`
    * `nodes` - List of TypesenseEx Node Configurations. Type: `[Node.config]`
  """
  @type t :: config_params()

  @callback next_node() :: {pid(), TypsenseNode.t()}

  @spec start_link(config_params()) :: Supervisor.t()
  def start_link(config) do
    case new(config) do
      {:ok, valid_config} -> Supervisor.start_link(Pool, valid_config)
      error -> error
    end
  end

  @impl true
  def init(%{nodes: nodes} = config) do
    nearest_node = Map.get(config, :nearest_node, %{})

    node_specs =
      nodes
      |> Enum.with_index()
      |> Enum.map(fn {node, index} ->
        is_nearest = node == nearest_node

        Supervisor.child_spec({Node, Map.merge(node, %{is_nearest: is_nearest})},
          id: {Node, index}
        )
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

  def next_node do
    nodes = Registry.lookup(NodeRegistry, :nodes)
    nearest = Enum.find(nodes, fn {_pid, node} -> node.is_nearest end)

    if nearest do
      nearest
    else
      Enum.random(nodes)
    end
  end

  @spec new(config_params()) :: {:ok, t()} | {:error, String.t()}
  defp new(config) do
    with :ok <- validate_nodes(config) do
      {:ok, config}
    end
  end

  @spec validate_nodes(config_params()) :: validation_response()
  defp validate_nodes(%{nodes: nodes}) when nodes == [] do
    {:error, "Configuration Contains an Empty Node List"}
  end

  defp validate_nodes(%{nodes: nodes}) when not is_list(nodes) do
    {:error, "Configuration Nodes Not a List"}
  end

  defp validate_nodes(map) when map == %{} do
    {:error, "Configuration Missing Nodes"}
  end

  defp validate_nodes(_config), do: :ok

  defp validate_nodes(%{nodes: nodes}) do
    nodes_valid? = Enum.all?(nodes, &Node.valid?/1)

    err_msg = "One or More Node Configurations Missing Data"

    if nodes_valid? do
      :ok
    else
      {:error, err_msg}
    end
  end

  defp validate_nodes(_config_without_nodes) do
    {:error, "Configuration Missing Node List"}
  end
end
