defmodule PoolTest do
  use ExUnit.Case, async: true

  alias Typesense.Pool

  test "new/1" do
    valid_nodes = [
      %{host: "example.com", port: "8989", protocol: "https"}
    ]

    assert {:ok,
            [
              {:ok,
               %Typesense.Node{
                 host: "example.com",
                 port: "8989",
                 protocol: "https",
                 is_nearest: false
               }}
            ]} = Pool.new(%{nodes: valid_nodes})

    assert {:node_errors, [error: _error1, error: _error2]} =
             Pool.new(%{nodes: [%{foo: :bar}, %{foo: :baz}]})

    assert {:ok,
            [
              ok: %Typesense.Node{is_nearest: true}
            ]} = Pool.new(%{nodes: valid_nodes, nearest_node: List.first(valid_nodes)})

    assert {:error, "Configuration Contains an Empty Node List"} = Pool.new(%{nodes: []})
    assert {:error, "Configuration Nodes Not a List"} = Pool.new(%{nodes: %{}})
    assert {:error, "Configuration Missing Nodes"} = Pool.new(%{})
  end

  test "start_link/1" do
    config = %{
      nodes: [
        %{host: "localhost", port: "8107", protocol: "https"}
      ]
    }

    pid = start_link_supervised!({Pool, Pool.new(config)})
    assert Process.alive?(pid)
  end

  test "start_link/1 with errors" do
    config = %{
      nodes: [
        %{host: "localhost", port: "8107", protocol: "flerg"}
      ]
    }

    assert_raise RuntimeError, ~r"protocol not in acceptable values", fn ->
      start_link_supervised!({Pool, Pool.new(config)})
    end

    assert_raise RuntimeError, ~r"Configuration Missing Nodes", fn ->
      start_link_supervised!({Pool, Pool.new(%{})})
    end
  end

  test "next_node/0" do
    config = %{
      nodes: [
        %{host: "localhost", port: "8107", protocol: "https"}
      ]
    }

    {:ok, pool} = Pool.new(config)

    start_link_supervised!({Pool, pool})

    assert {_pid,
            %Typesense.Node{
              host: "localhost",
              port: "8107",
              protocol: "https",
              is_nearest: false
            }} = Pool.next_node()
  end
end
