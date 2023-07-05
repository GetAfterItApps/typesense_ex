defmodule TypesenseEx.RequestConfig do
  use GenServer

  @typedoc "A Typesense API key"
  @type api_key :: String.t() | nil

  @typedoc "Whether or not a validation has failed"
  @type validation_response :: :ok | {:error, String.t()}

  @typedoc """
  Configuration

    @type api_key :: String.t() | nil

  ## Fields

    * `api_key` - (recommended) TypesenseEx API key. Type: `String`
    * `connection_timeout_seconds` - [defaults to 10] Establishes how long TypesenseEx should wait before retrying a request to a typesense node after timing out. Type: `integer`
    * `healthcheck_interval_seconds` - [defaults to 15] The number of seconds to wait before resuming requests for a node after it has been marked unhealthy. Type: `integer`
    * `num_retries` - [defaults to 3] The number of retry attempts that should be made before marking a node unhealthy. Type: `integer`
    * `retry_interval_seconds` - [defaults to 0.1] The number of seconds to wait between retries. Type: `float`
  """

  @type config_params ::
          %{
            api_key: api_key(),
            connection_timeout_seconds: integer(),
            healthcheck_interval_seconds: integer(),
            num_retries: integer(),
            retry_interval_seconds: float()
          }

  @typedoc """
  RequestConfig

  ## Fields

    * `api_key` - (recommended) TypesenseEx API key. Type: `String`
    * `connection_timeout_seconds` - [defaults to 10] Establishes how long TypesenseEx should wait before retrying a request to a typesense node after timing out. Type: `integer`
    * `healthcheck_interval_seconds` - [defaults to 15] The number of seconds to wait before resuming requests for a node after it has been marked unhealthy. Type: `integer`
    * `num_retries` - [defaults to 3] The number of retry attempts that should be made before marking a node unhealthy. Type: `integer`
    * `retry_interval_seconds` - [defaults to 0.1] The number of seconds to wait between retries. Type: `float`
  """
  @type t :: config_params()

  defstruct api_key: "",
            connection_timeout_seconds: 10,
            healthcheck_interval_seconds: 15,
            num_retries: 3,
            retry_interval_seconds: 0.1

  @callback get_config :: RequestConfig.t()

  #############
  # Bootstrap #
  #############

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
  A convenience to get back the RequestConfig struct
  """
  @spec get_config() :: t()
  def get_config do
    GenServer.call(RequestConfig, :config)
  end

  @impl true
  @spec handle_call(:config, GenServer.from(), t()) :: {:reply, t(), t()}
  def handle_call(:config, _from, config) do
    {:reply, config, config}
  end

  @spec new(config_params()) :: {:ok, t()} | {:error, String.t()}
  defp new(config) do
    case validate_api_key(config) do
      :ok -> {:ok, struct(RequestConfig, config)}
      error -> error
    end
  end

  @spec validate_api_key(config_params()) :: validation_response()
  defp validate_api_key(%{api_key: api_key}) when is_binary(api_key), do: :ok

  defp validate_api_key(_config_) do
    {:error, "Configuration Missing API Key"}
  end
end
