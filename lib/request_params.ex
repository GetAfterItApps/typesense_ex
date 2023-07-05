defmodule Typesense.RequestParams do
  alias __MODULE__
  alias Typesense.Node
  defstruct [:method, :url, :query, :body, :headers]

  @type method :: atom()
  @type path :: String.t()
  @type body :: map() | String.t() | nil
  @type params :: Keyword.t() | []
  @type header :: {String.t(), String.t()}
  @type headers :: [header] | []

  def new(node, method, path, body \\ %{}, query \\ [], api_key \\ nil) do
    headers =
      []
      |> apply_content_type(body)
      |> maybe_apply_api_key(api_key)

    %RequestParams{
      method: method,
      url: url_for(node, path),
      query: query,
      body: maybe_json(body),
      headers: headers
    }
  end

  @spec url_for(Node.t(), path()) :: binary
  defp url_for(%Node{protocol: protocol, host: host, port: port}, path) do
    URI.encode("#{protocol}://#{host}:#{port}#{path}")
  end

  @spec apply_content_type(headers(), body()) :: headers()
  defp apply_content_type(headers, body) when is_map(body) do
    [{"Content-Type", "application/json"} | headers]
  end

  defp apply_content_type(headers, body) when is_binary(body) do
    [{"Content-Type", "text/plain"} | headers]
  end

  defp apply_content_type(headers, body) when is_nil(body) do
    headers
  end

  @spec maybe_json(map() | String.t() | nil) :: String.t()

  defp maybe_json(body) when is_nil(body), do: nil

  defp maybe_json(body) when is_map(body) do
    Jason.encode!(body)
  end

  defp maybe_json(body), do: body

  defp maybe_apply_api_key(headers, nil), do: headers

  defp maybe_apply_api_key(headers, api_key) do
    [{"X-TYPESENSE-API-KEY", api_key} | headers]
  end
end
