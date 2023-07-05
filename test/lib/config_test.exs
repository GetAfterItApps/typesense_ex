defmodule TypesenseEx.ConfigTest do
  use ExUnit.Case
  alias TypesenseEx.Config
  alias TypesenseEx.Node

  @valid_nodes [
    %{host: "localhost", port: "8107", protocol: "https"},
    %{host: "localhost", port: "8108", protocol: "https"},
    %{host: "localhost", port: "8109", protocol: "https"}
  ]

  @minimal_valid_config %{
    api_key: "123",
    nodes: @valid_nodes
  }

  test "start_link/1" do
    {:ok, pid} = Config.start_link(@minimal_valid_config)
    assert Process.alive?(pid)
  end

  test "start_link/1 with invalid config" do
    assert_misconfig(%{nodes: []}, "Configuration Contains an Empty Node List")
    assert_misconfig(%{}, "Configuration Missing Nodes")
    assert_misconfig(%{nodes: :nodes}, "Configuration Nodes Not a List")
  end

  test "start_link/1 with invalid nearest_node" do
    assert_misconfig(
      Map.merge(@minimal_valid_config, %{
        nearest_node: %{host_zzzz: "localhost", port: "8107", protocol: "https"}
      }),
      "Invalid Nearest Node Specification"
    )
  end

  test "start_link/1 with invalid nodes" do
    assert_misconfig(
      Map.merge(@minimal_valid_config, %{
        nodes: [%{host_zzz: "localhost", port: "8107", protocol: "https"}]
      }),
      "One or More Node Configurations Missing Data"
    )
  end

  test "start_link/1 with missing nodes" do
    assert_misconfig(
      Map.delete(@minimal_valid_config, :nodes),
      "Configuration Missing Node List"
    )
  end

  test "start_link/1 with invalid api_key" do
    assert_misconfig(
      Map.merge(@minimal_valid_config, %{api_key: 123}),
      "Configuration Missing API Key"
    )
  end
end
