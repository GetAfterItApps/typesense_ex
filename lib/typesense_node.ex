defmodule Typesense.TypesenseNode do
  @moduledoc """
  Type and validation functions for a Typesense node
  """
  alias __MODULE__

  @type health_status :: :healthy | :unhealthy | :maybe_healthy

  @type t :: %TypesenseNode{
          host: String.t(),
          port: String.t(),
          protocol: String.t(),
          health_status: health_status,
          health_set_on: DateTime.t()
        }

  @type config :: %{
          host: String.t(),
          port: String.t(),
          protocol: String.t()
        }

  defstruct [
    :host,
    :port,
    :protocol,
    health_status: :healthy,
    health_set_on: DateTime.utc_now()
  ]

  @spec new(TypesenseNode.config()) :: TypesenseNode.t()
  def new(config) do
    struct(TypesenseNode, config)
  end

  @spec to_config(TypesenseNode.t()) :: config()
  def to_config(%TypesenseNode{} = node) do
    Map.take(node, [:host, :port, :protocol])
  end

  @spec valid?(TypesenseNode.config()) :: boolean()
  def valid?(node) do
    is_binary(node[:host]) and
      is_binary(node[:port]) and
      is_binary(node[:protocol])
  end
end
