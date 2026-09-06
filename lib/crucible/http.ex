defmodule Crucible.HTTP do
  @moduledoc """
  HTTP for cloud control planes.

  Prefers **Gale** when loaded. H1/H2 still Req/Finch. Inject `:http`
  (arity-3 fun) for tests.

  Do not pass `protocols: [:http3]` on Fly/Hetzner/AWS.
  """

  def get(url, opts \\ []), do: request(:get, url, opts)
  def post(url, opts \\ []), do: request(:post, url, opts)
  def put(url, opts \\ []), do: request(:put, url, opts)
  def delete(url, opts \\ []), do: request(:delete, url, opts)

  def request(method, url, opts \\ []) when is_list(opts) do
    opts = Keyword.put_new(opts, :protocols, [:http1, :http2])

    result =
      cond do
        is_function(Keyword.get(opts, :http), 3) ->
          Keyword.get(opts, :http).(method, url, opts)

        gale?() ->
          apply(Gale, :request, [method, url, Keyword.delete(opts, :http)])

        req?() ->
          Req.request([method: method, url: url] ++ Keyword.drop(opts, [:protocols, :http]))

        true ->
          {:error, :no_http_client}
      end

    normalize(result)
  end

  def client do
    cond do
      gale?() -> :gale
      req?() -> :req
      true -> :none
    end
  end

  def json_headers(token) when is_binary(token) do
    [
      {"authorization", "Bearer " <> token},
      {"content-type", "application/json"}
    ]
  end

  defp gale?,
    do: Code.ensure_loaded?(Gale) and function_exported?(Gale, :request, 3)

  defp req?,
    do: Code.ensure_loaded?(Req) and function_exported?(Req, :request, 1)

  defp normalize({:ok, %{status: status, body: body} = resp}) do
    {:ok,
     %{
       status: status,
       body: decode_body(body),
       headers: Map.get(resp, :headers, [])
     }}
  end

  defp normalize({:error, reason}), do: {:error, reason}
  defp normalize(other), do: {:error, {:unexpected_http, other}}

  defp decode_body(body) when is_map(body), do: body

  defp decode_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, map} -> map
      _ -> body
    end
  end

  defp decode_body(body), do: body
end
