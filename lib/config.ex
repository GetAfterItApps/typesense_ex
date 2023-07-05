defmodule TypesenseEx.Config do
  use GenServer
  alias __MODULE__

  @typedoc """
  Configuration Params

  ## Fields

    * `nearest_node` - (optional) node configuration for geographically nearest node (for optimizing network latency) . Type: `Node.config`
    * `api_key` - (recommended) TypesenseEx API key. Type: `String`
    * `nodes` - List of TypesenseEx Node Configurations. Type: `[Node.config]`
    * `connection_timeout_seconds` - [defaults to 10] Establishes how long TypesenseEx should wait before retrying a request to a typesense node after timing out. Type: `integer`
    * `healthcheck_interval_seconds` - [defaults to 15] The number of seconds to wait before resuming requests for a node after it has been marked unhealthy. Type: `integer`
    * `num_retries` - [defaults to 3] The number of retry attempts that should be made before marking a node unhealthy. Type: `integer`
    * `retry_interval_seconds` - [defaults to 0.1] The number of seconds to wait between retries. Type: `float`
  """

  @type config_params ::
          %{
            optional(:nearest_node) => Node.config(),
            api_key: api_key(),
            nodes: [Node.config()],
            connection_timeout_seconds: integer(),
            healthcheck_interval_seconds: integer(),
            num_retries: integer(),
            retry_interval_seconds: float()
          }

  @typedoc "Whether or not a validation has failed"
  @type validation_response :: :ok | {:error, String.t()}
  @typedoc "A list of Node Configurations"
  @type nodes :: [Node.config()]
  @typedoc "A Typesense API key"
  @type api_key :: String.t() | nil

  @typedoc """
  The Configuration

  ## Fields

    * `nearest_node` - (optional) node configuration for geographically nearest node (for optimizing network latency) . Type: `Node.config`
    * `api_key` - (recommended) TypesenseEx API key. Type: `String`
    * `nodes` - List of TypesenseEx Node Configurations. Type: `[Node.config]`
    * `connection_timeout_seconds` - [defaults to 10] Establishes how long TypesenseEx should wait before retrying a request to a typesense node after timing out. Type: `integer`
    * `healthcheck_interval_seconds` - [defaults to 15] The number of seconds to wait before resuming requests for a node after it has been marked unhealthy. Type: `integer`
    * `num_retries` - [defaults to 3] The number of retry attempts that should be made before marking a node unhealthy. Type: `integer`
    * `retry_interval_seconds` - [defaults to 0.1] The number of seconds to wait between retries. Type: `float`
  """
  @type t :: config_params()

  defstruct [
    :nodes,
    api_key: "",
    nearest_node: nil,
    connection_timeout_seconds: 10,
    healthcheck_interval_seconds: 15,
    num_retries: 3,
    retry_interval_seconds: 0.1
  ]

  @spec start_link(config_params()) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  @spec init(config_params()) :: {:ok, t()} | {:stop, any()}
  def init(config) do
    case new(config) do
      {:ok, config} ->
        {:ok, config}

      {:error, msg} ->
        {:stop, msg}
    end
  end

  @doc """
  A convenience to get back the Config struct
  """
  @spec get() :: t()
  def get do
    GenServer.call(self(), :config)
  end

  @impl true
  @spec handle_call(:config, GenServer.from(), t()) ::
          {:reply, t(), t()}
  def handle_call(:config, _from, config) do
    {:reply, config, config}
  end

  @spec new(config_params()) :: {:ok, t()} | {:error, String.t()}
  defp new(config) do
    with :ok <- validate_nodes(config),
         :ok <- validate_nearest_node(config),
         :ok <- validate_api_key(config) do
      {:ok, struct(Config, config)}
    end
  end

  @spec validate_api_key(config_params()) :: validation_response()
  defp validate_api_key(%{api_key: api_key}) when is_binary(api_key), do: :ok

  defp validate_api_key(_config_) do
    {:error, "Configuration Missing API Key"}
  end

  @spec validate_nearest_node(config_params()) :: validation_response()
  defp validate_nearest_node(config) when not is_map_key(config, :nearest_node), do: :ok

  defp validate_nearest_node(%{nearest_node: nearest_node_config}) do
    if node_valid?(nearest_node_config) do
      :ok
    else
      {:error, "Invalid Nearest Node Specification"}
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

  defp validate_nodes(%{nodes: nodes}) do
    nodes_valid? = Enum.all?(nodes, &node_valid?/1)

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

  @spec node_valid?(Node.config()) :: boolean()
  defp node_valid?(node) do
    is_binary(node[:host]) and
      is_binary(node[:port]) and
      is_binary(node[:protocol])
  end
end
