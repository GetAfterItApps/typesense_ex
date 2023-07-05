defmodule Typesense.ConfigTest do
  use TypesenseCase
  alias Typesense.Config

  test "validate/1 nodes" do
    assert %Config{
             errors: [
               "Configuration Contains an Empty Node List"
             ]
           } = Config.new(%{nodes: []}) |> Config.validate()

    assert %Config{
             errors: [
               "Expected nodes to be a list but got 'nil'"
             ]
           } = Config.new(%{}) |> Config.validate()

    assert %Config{
             errors: [
               "Expected nodes to be a list but got ':nodes'"
             ]
           } = Config.new(%{nodes: :nodes}) |> Config.validate()
  end

  test "validate/1 node" do
    assert %Config{
             errors: [
               "protocol not in acceptable values [http, https]"
             ]
           } =
             Config.new(%{nodes: [%{host: "foo.com", port: "8383", protocol: "hhtps"}]})
             |> Config.validate()

    assert %Config{
             errors: [
               "Node Config Missing host. Keys Found: port, protocol"
             ]
           } = Config.new(%{nodes: [%{port: "8383", protocol: "https"}]}) |> Config.validate()

    assert %Config{
             errors: [
               "port is not an integer"
             ]
           } =
             Config.new(%{nodes: [%{host: "foo.com", port: "z8383", protocol: "https"}]})
             |> Config.validate()

    assert %Config{
             errors: [
               "Invalid characters for port: 'x'"
             ]
           } =
             Config.new(%{nodes: [%{host: "foo.com", port: "8383x", protocol: "https"}]})
             |> Config.validate()
  end
end
