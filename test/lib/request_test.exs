defmodule TypesenseEx.RequestTest do
  use TypesenseCase, async: false
  alias TypesenseEx.MockHttp
  alias TypesenseEx.MockPool
  alias TypesenseEx.MockRequestConfig
  alias TypesenseEx.RequestConfig
  alias TypesenseEx.Pool
  alias TypesenseEx.Request
  alias TypesenseEx.Node

  test "request/5 returns and decodes a valid response" do
    MockPool
    |> expect(:next_node, 1, fn ->
      {:pid_here, %Node{port: 1122, host: "example.com", protocol: "https"}}
    end)

    MockRequestConfig
    |> expect(:get_config, 2, fn ->
      %RequestConfig{
        api_key: "sdfsdf",
        connection_timeout_seconds: 4,
        healthcheck_interval_seconds: 15,
        num_retries: 3,
        retry_interval_seconds: 0.1
      }
    end)

    MockHttp
    |> expect(:request, 1, fn _client, _options ->
      {:ok, %Tesla.Env{status: 200, body: "{\"results\": []}"}}
    end)
    |> expect(:client, 1, fn _middleware ->
      {:ok, %Tesla.Env{status: 200, body: "{\"results\": []}"}}
    end)

    assert Request.new() |> Request.execute(:get, "/fake-endpoint") == %TypesenseEx.Request{
             node:
               {:pid_here,
                %TypesenseEx.Node{
                  host: "example.com",
                  is_nearest: false,
                  port: 1122,
                  protocol: "https"
                }},
             raw_response:
               {:ok,
                %Tesla.Env{
                  __client__: nil,
                  __module__: nil,
                  body: "{\"results\": []}",
                  headers: [],
                  method: nil,
                  opts: [],
                  query: [],
                  status: 200,
                  url: ""
                }},
             request_config: %TypesenseEx.RequestConfig{
               api_key: "sdfsdf",
               connection_timeout_seconds: 4,
               healthcheck_interval_seconds: 15,
               num_retries: 3,
               retry_interval_seconds: 0.1
             },
             request_params: %TypesenseEx.RequestParams{
               body: "{}",
               headers: [{"X-TYPESENSE-API-KEY", "sdfsdf"}, {"Content-Type", "application/json"}],
               method: :get,
               query: [],
               url: "https://example.com:1122/fake-endpoint"
             },
             response: nil,
             retries: 0
           }
  end

  test "request/5 handles jsonl responses" do
    MockHttp
    |> expect(:request, 1, fn _client, _options ->
      {:ok, %Tesla.Env{status: 200, body: "{\"success\":true}\n{\"success\":true}"}}
    end)
    |> expect(:client, 1, fn _middleware ->
      {:ok, %Tesla.Env{status: 200, body: "{\"results\": []}"}}
    end)

    assert Request.new() |> Request.execute(:get, "/fake-endpoint") ==
             {:ok, [%{"success" => true}, %{"success" => true}]}
  end

  test "request/5 encodes in text/plain when given a string body" do
    MockHttp
    |> expect(:request, 3, fn _client, params ->
      assert {"Content-Type", "text/plain"} in Keyword.get(params, :headers)
      {:ok, %Tesla.Env{status: 500, body: "{}"}}
    end)
    |> expect(:client, 3, fn _middleware ->
      {:ok, %Tesla.Env{status: 200, body: "{\"results\": []}"}}
    end)

    assert Request.new() |> Request.execute(:get, "/fake-endpoint", "string body") ==
             {:error,
              %Tesla.Env{
                __client__: nil,
                __module__: nil,
                body: "{}",
                headers: [],
                method: nil,
                opts: [],
                query: [],
                status: 500,
                url: ""
              }}
  end

  @first_node_params [
    method: :get,
    url: "https://localhost:8107/fake-endpoint",
    query: [],
    body: "{}",
    headers: [
      {"X-TYPESENSE-API-KEY", "123"},
      {"Content-Type", "application/json"}
    ]
  ]

  test "request/5 retries, marks nodes healthy/unhealthy if they fail/succeed" do
    MockHttp
    |> expect(:request, 3, fn _client, _params ->
      {:ok, %Tesla.Env{status: 500, body: "{}"}}
    end)
    |> expect(:client, 3, fn _middleware -> %Tesla.Client{} end)

    assert Request.new() |> Request.execute(:get, "/fake-endpoint") ==
             {:error,
              %Tesla.Env{
                __client__: nil,
                __module__: nil,
                body: "{}",
                headers: [],
                method: nil,
                opts: [],
                query: [],
                status: 500,
                url: ""
              }}

    # The failed node is marked unhealthy and then
    # immediately unhealthy since healthcheck_interval_seconds == 0
    assert Pool.next_node().port == "8108"
    maybe_recovered_node = Pool.next_node()
    assert maybe_recovered_node.port == "8107"
    assert maybe_recovered_node.health_status == :maybe_healthy

    # Skip requesting 8108 so that we can demonstrate a node
    # (8107) becoming healthy again below
    Pool.next_node()

    MockHttp
    |> expect(:request, 1, fn _client, @first_node_params ->
      {:ok, %Tesla.Env{status: 200, body: "{}"}}
    end)
    |> expect(:client, 1, fn _middleware -> %Tesla.Client{} end)

    assert Request.new() |> Request.execute(:get, "/fake-endpoint") == {:ok, %{}}

    # Skip 8108 again
    Pool.next_node()

    # 8107 was requested again since its status was :maybe_healthy
    # and this time it returned a 200 status, so it's status should
    # have been marked :healthy again
    maybe_recovered_node = Pool.next_node()
    assert maybe_recovered_node.port == "8107"
    assert maybe_recovered_node.health_status == :healthy
  end

  test "start_link/1 with invalid api_key" do
    assert_misconfig(
      Request,
      Map.merge(@minimal_valid_config, %{api_key: 123}),
      "Configuration Missing API Key"
    )
  end
end
