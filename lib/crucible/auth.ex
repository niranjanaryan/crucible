defmodule Crucible.Auth do
  @moduledoc "Pick bearer vs AWS SigV4 headers for a REST call."

  alias Crucible.Auth.SigV4

  def headers(state, method, url, body, extra_headers \\ []) do
    body_bin = encode_body(body)

    case state.meta[:auth] do
      :sigv4 ->
        case SigV4.credentials(state.opts) do
          {:ok, access, secret, region} ->
            hdrs =
              if body_bin != "" do
                [{"content-type", "application/json"} | extra_headers]
              else
                extra_headers
              end

            SigV4.sign(method, url, hdrs, body_bin,
              access_key: access,
              secret_key: secret,
              region: Keyword.get(state.opts, :region, region),
              service: state.meta[:service] || "execute-api",
              datetime: Keyword.get(state.opts, :datetime)
            )

          :error ->
            extra_headers
        end

      :gcp ->
        token =
          state.token ||
            case Crucible.Auth.GCP.access_token(state.opts) do
              {:ok, t} -> t
              _ -> "test"
            end

        Crucible.HTTP.json_headers(token) ++ extra_headers

      _ ->
        Crucible.HTTP.json_headers(state.token || "test") ++ extra_headers
    end
  end

  def encode_body(nil), do: ""
  def encode_body(bin) when is_binary(bin), do: bin

  def encode_body(map) when is_map(map) do
    Jason.encode!(map)
  end

  def ready?(%{meta: %{auth: :sigv4}} = state) do
    match?({:ok, _, _, _}, SigV4.credentials(state.opts)) or is_function(state.http, 3)
  end

  def ready?(%{meta: %{auth: :gcp}} = state) do
    is_function(state.http, 3) or match?({:ok, _}, Crucible.Auth.GCP.access_token(state.opts)) or
      (is_binary(state.token) and state.token != "")
  end

  def ready?(%{http: f}) when is_function(f, 3), do: true
  def ready?(%{token: t}) when is_binary(t) and t != "", do: true
  def ready?(_), do: false
end
