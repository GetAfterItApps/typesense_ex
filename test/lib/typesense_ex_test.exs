defmodule TypesenseTest do
  use TypesenseCase, async: false

  test "start_link/1" do
    pid = start_link_supervised!({Typesense, @minimal_valid_config})
    assert Process.alive?(pid)
  end
end
