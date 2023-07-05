defmodule TypesenseEx.RequestParamsTest do
  use ExUnit.Case

  import TypesenseEx.RequestParams

  test "new/6 builds request parameters correctly" do
    node = %{protocol: "http", host: "example.com", port: 8080}
    method = "GET"
    path = "/search"
    body = %{query: "example"}
    query = [page: 1, per_page: 10]
    api_key = "secret-key"

    expected_headers = [
      {"Content-Type", "application/json"},
      {"X-TYPESENSE-API-KEY", "secret-key"}
    ]

    expected_params = %RequestParams{
      method: "GET",
      url: "http://example.com:8080/search",
      query: [page: 1, per_page: 10],
      body: %{query: "example"},
      headers: expected_headers
    }

    assert new(node, method, path, body, query, api_key) == expected_params
  end
end
