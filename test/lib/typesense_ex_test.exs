defmodule TypesenseExTest do
  use TypesenseCase, async: false

  test "start_link/1" do
    pid = start_link_supervised!({TypesenseEx, @minimal_valid_config})
    assert Process.alive?(pid)
  end
end
