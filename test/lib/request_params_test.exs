defmodule Typesense.RequestParamsTest do
  use ExUnit.Case

  alias Typesense.RequestParams
  alias Typesense.Node


  test "new/6 builds request parameters correctly" do
    node = %Node{protocol: "http", host: "example.com", port: 8080}
    method = "GET"
    path = "/search"
    body = %{query: "example"}
    query = [page: 1, per_page: 10]
    api_key = "secret-key"

    expected_headers = [
      {"X-TYPESENSE-API-KEY", "secret-key"},
      {"Content-Type", "application/json"}
    ]

    expected_params = %RequestParams{
      method: "GET",
      url: "http://example.com:8080/search",
      query: [page: 1, per_page: 10],
      body: "{\"query\":\"example\"}",
      headers: expected_headers
    }

    assert expected_params == RequestParams.new(node, method, path, body, query, api_key)
  end
end
