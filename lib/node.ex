defmodule TypesenseEx.Node do
  use GenServer

  @moduledoc """
  Type and validation functions for a TypesenseEx node
  """
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

  defstruct [
    :host,
    :port,
    :protocol,
    is_nearest: false
  ]

  @callback set_unhealthy(pid(), integer()) :: :ok

  @spec start_link(config()) :: GenServer.on_start()
  def start_link(config) do
    with :ok <- validate(config) do
      GenServer.start_link(Node, config |> new())
    end
  end

  @impl true
  @spec init(t()) :: {:ok, t()}
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

  @spec validdate(config()) :: :ok | {:error, String.t()}
  defp validdate(config) do
    with :ok <- present?(Map.get(config, :port), "Port"),
         :ok <- present?(Map.get(config, :port), "Port"),
         :ok <- contains?("Protocol", Map.get(config, :protoco), ["http", "https"]) do
      :ok
    end
  end

  def contains?(name, value, valid_values) do
    if value in valid_values do
      :ok
    else
      {:error, "#{Name} #{value} not in #{valid_values.inspect}"}
    end
  end

  defp present?(name, nil), do: {:error, "Missing #{name}"}
  defp present?(_name, _value), do: :ok

  defp register(node) do
    Registry.register(NodeRegistry, :nodes, node)

    node
  end
end
