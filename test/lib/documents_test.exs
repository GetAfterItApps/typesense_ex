defmodule Typesense.DocumentTest do
  use TypesenseCase, async: true
  alias Typesense.Documents
  alias Typesense.MockRequest

  test "create/2" do
    doc = docs(1) |> List.first()

    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :post
      assert path == "/collections/foo/documents"
      assert body == doc
      assert options == []
    end)

    Documents.create("foo", doc)
  end

  test "upsert/3" do
    doc = docs(1) |> List.first()

    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :post
      assert path == "/collections/foo/documents"
      assert body == doc
      assert options == [{:action, :upsert}]
    end)

    Documents.upsert("foo", doc)
  end

  test "update/3" do
    doc = docs(1) |> List.first()

    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :post
      assert path == "/collections/foo/documents"
      assert body == doc
      assert options == [{:action, :update}]
    end)

    Documents.update("foo", doc)
  end

  test "partial_update/3" do
    doc = docs(1) |> List.first()

    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :patch
      assert path == "/collections/foo/documents/0"
      assert body == doc
      assert options == []
    end)

    Documents.partial_update("foo", doc)
  end

  test "retrieve/3" do
    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :patch
      assert path == "/collections/foo/documents/0"
      assert body == nil
      assert options == []
    end)

    Documents.retrieve("foo", "0")
  end

  test "delete/2 when is_integer(document_id) " do
    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :delete
      assert path == "/collections/foo/documents"
      assert body == nil
      assert options == "0"
    end)

    Documents.delete("foo", "0")
  end

  test "delete/2 " do
    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :delete
      assert path == "/collections/foo/documents"
      assert body == nil
      assert options == %{filter_by: "foo"}
    end)

    Documents.delete("foo", %{filter_by: "foo"})
  end

  test "search/2 " do
    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :delete
      assert path == "/collections/foo/documents"
      assert body == nil
      assert options == %{q: "foo", query_by: "title"}
    end)

    Documents.delete("foo", %{q: "foo", query_by: "title"})
  end

  test "import_documents/3" do
    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :post
      assert path == "/collections/companies/documents/import"

      assert body ==
               "{\"id\":0,\"location_name\":\"Jeff's Litterbox Hotel 0\",\"num_employees\":0}\n{\"id\":1,\"location_name\":\"Jeff's Litterbox Hotel 1\",\"num_employees\":1}\n{\"id\":2,\"location_name\":\"Jeff's Litterbox Hotel 2\",\"num_employees\":2}"

      assert options == [{:action, :insert}]
    end)

    Documents.import_documents("companies", docs(2), action: :insert)
  end

  test "import_documents/3 with JSONL" do
    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :post
      assert path == "/collections/companies/documents/import"

      assert body ==
               "{\"id\": \"1\", \"location_name\": \"Jeff's Litterbox Hotel 0\", num_employees: 1}\n"

      assert options == [{:action, :insert}]
    end)

    docs = """
    {"id": "1", "location_name": "Jeff's Litterbox Hotel 0", num_employees: 1}
    """

    Documents.import_documents("companies", docs, action: :insert)
  end

  test "import_documents/3 with no documents given" do
    assert {:error, "No documents were given"} =
             Documents.import_documents("companies", [], action: :insert)
  end

  test "export_documents/2" do
    MockRequest
    |> expect(:execute_request, 1, fn method, path, body, options ->
      assert method == :get
      assert path == "/collections/companies/documents/export"
      assert body == nil
      assert options == []
    end)

    Documents.export_documents("companies")
  end

  def expect(expected_options) do
    MockRequest
    |> expect(:execute_request, 1, fn _method, _path, _body, options ->
      assert expected_options == options
      {:ok, {}}
    end)
  end

  def docs(count) do
    Enum.map(0..count, fn index ->
      %{
        "id" => index,
        "location_name" => "Jeff's Litterbox Hotel #{index}",
        "num_employees" => index
      }
    end)
  end
end
