defmodule PoolTest do
  use ExUnit.Case

  alias TypesenseEx.Pool

  test "start_link/1" do
    nodes = [
      %{host: "localhost", port: "8107", protocol: "https"}
    ]

    pid = start_link_supervised!({Pool, nodes})
    assert Process.alive?(pid)
  end

  test "next_node/0" do
    nodes = [
      %{host: "localhost", port: "8107", protocol: "https"}
    ]

    start_link_supervised!({Pool, nodes})

    assert {_pid,
            %TypesenseEx.Node{
              host: "localhost",
              port: "8107",
              protocol: "https",
              is_nearest: false
            }} = Pool.next_node()
  end
end
