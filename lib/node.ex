defmodule Typesense.Node do
  @moduledoc """
  Type and validation functions for a Typesense node
  """
  use GenServer
  alias __MODULE__

  @type from :: {pid(), tag :: term()}
  @type seconds_removed :: float()

  @type t :: %Node{
          host: String.t(),
          port: String.t(),
          protocol: String.t(),
          is_nearest: boolean()
        }

  @type config :: %{
          host: String.t(),
          port: String.t(),
          protocol: String.t(),
          is_nearest: boolean()
        }
  @type error :: {:error, {String.t(), config()}}

  @type maybe_node :: {:ok, t} | error()

  defstruct [
    :host,
    :port,
    :protocol,
    is_nearest: false
  ]

  @callback set_unhealthy(pid(), integer()) :: :ok

  @spec new(config()) :: t
  def new(config) do
    struct(Node, config)
  end

  def start_link(%Node{} = node) do
    GenServer.start_link(Node, node)
  end

  @impl true
  @spec init(t()) :: {:ok, t}
  def init(node) do
    {:ok, node |> register()}
  end

  @spec set_unhealthy(pid(), integer()) :: :ok
  def set_unhealthy(pid, seconds) do
    GenServer.cast(pid, {:remove_for, seconds})
  end

  @impl true
  def handle_cast({:remove_for, seconds_removed}, node) do
    Registry.unregister(NodeRegistry, :nodes)
    Process.send_after(self(), :register, seconds_removed)

    {:noreply, node}
  end

  @spec register(t()) :: t
  defp register(node) do
    Registry.register(NodeRegistry, :nodes, node)

    node
  end
end
