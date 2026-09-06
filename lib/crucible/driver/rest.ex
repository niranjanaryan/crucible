defmodule Crucible.Driver.REST do
  @moduledoc """
  Generic REST compute driver. Codec per cloud (`:digitalocean`, `:vultr`, …).
  """
  @behaviour Crucible.Driver

  alias Crucible.{HTTP, Providers}

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :provider)
    meta = Providers.get(name) || %{kind: :rest}

    {:ok,
     %{
       provider: name,
       meta: meta,
       token: Keyword.get(opts, :token) || token_from_env(meta),
       http: Keyword.get(opts, :http),
       opts: opts
     }}
  end

  @impl true
  def boot(state, spec) do
    with {:ok, codec} <- codec(state),
         :ok <- need_token(state),
         {method, path, body} <- codec.create(state, spec),
         {:ok, %{status: status, body: resp}} when status in 200..299 <-
           http(state, method, url(state, path), json: body) do
      {:ok, to_machine(codec, state, resp), state}
    else
      {:error, _} = err -> err
      {:ok, %{status: status, body: body}} -> {:error, {:rest_http, state.provider, status, body}}
    end
  end

  @impl true
  def await(state, machine, timeout) do
    with {:ok, codec} <- codec(state) do
      deadline = System.monotonic_time(:millisecond) + timeout
      poll(state, codec, machine, deadline)
    end
  end

  @impl true
  def shutdown(state, machine) do
    with {:ok, codec} <- codec(state),
         :ok <- need_token(state),
         {method, path} <- call(codec, :delete, state, machine),
         {:ok, %{status: status}} when status in 200..299 <- http(state, method, url(state, path)) do
      :ok
    else
      {:error, _} = err -> err
      {:ok, %{status: status, body: body}} -> {:error, {:rest_http, state.provider, status, body}}
    end
  end

  @impl true
  def describe(state, machine) do
    with {:ok, codec} <- codec(state),
         {method, path} <- call(codec, :get, state, machine),
         {:ok, %{status: 200, body: body}} <- http(state, method, url(state, path)) do
      {:ok, Map.from_struct(to_machine(codec, state, body))}
    else
      {:error, _} = err -> err
      {:ok, %{status: status, body: body}} -> {:error, {:rest_http, state.provider, status, body}}
    end
  end

  defp poll(state, codec, machine, deadline) do
    if System.monotonic_time(:millisecond) > deadline do
      {:error, :await_timeout}
    else
      {method, path} = call(codec, :get, state, machine)

      case http(state, method, url(state, path)) do
        {:ok, %{status: 200, body: body}} ->
          m = to_machine(codec, state, body)

          if m.state == :running do
            {:ok, m, state}
          else
            Process.sleep(150)
            poll(state, codec, m, deadline)
          end

        other ->
          {:error, other}
      end
    end
  end

  def list_sizes(state) do
    with {:ok, codec} <- codec(state) do
      if function_exported?(codec, :list_sizes, 1) do
        apply(codec, :list_sizes, [state])
      else
        {:error, :not_supported}
      end
    end
  end

  defp codec(%{meta: %{codec: name}}) when name not in [nil, :json] do
    Crucible.Driver.REST.Codec.get(name)
  end

  defp codec(%{meta: %{kind: :rest}}), do: {:ok, Crucible.Driver.REST.Json}
  defp codec(%{meta: %{codec: :json}}), do: {:ok, Crucible.Driver.REST.Json}
  defp codec(%{provider: p}), do: {:error, {:rest_codec_missing, p}}

  defp call(codec, fun, state, machine) do
    if function_exported?(codec, fun, 2) do
      apply(codec, fun, [state, machine])
    else
      apply(codec, fun, [machine])
    end
  end

  defp to_machine(codec, state, body) do
    if function_exported?(codec, :to_machine, 3) do
      codec.to_machine(body, state.provider, state.meta)
    else
      codec.to_machine(body, state.provider)
    end
  end

  defp url(state, path) do
    base = String.trim_trailing(state.meta[:base] || "", "/")
    base <> path
  end

  defp token_from_env(%{token_env: env}) when is_binary(env), do: System.get_env(env)
  defp token_from_env(_), do: nil

  defp need_token(state) do
    if Crucible.Auth.ready?(state), do: :ok, else: {:error, {:token_required, state.provider}}
  end

  defp http(state, method, url, extra \\ []) do
    json = Keyword.get(extra, :json)
    body = if json, do: Crucible.Auth.encode_body(json), else: ""
    headers = Crucible.Auth.headers(state, method, url, body)

    extra =
      extra
      |> Keyword.delete(:json)
      |> Keyword.put(:headers, headers)
      |> Keyword.put(:http, state.http)
      |> then(fn kw ->
        if json, do: Keyword.put(kw, :body, body), else: kw
      end)

    HTTP.request(method, url, extra)
  end
end
