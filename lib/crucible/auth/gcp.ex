defmodule Crucible.Auth.GCP do
  @moduledoc """
  Google access tokens for Compute Engine.

  Order:

  1. `opts[:token]` / `GOOGLE_ACCESS_TOKEN` / `CLOUDSDK_AUTH_ACCESS_TOKEN`
  2. GCE metadata server (when this process runs **on** a GCP VM)
  3. `gcloud auth print-access-token`
  4. Service account JSON (`GOOGLE_APPLICATION_CREDENTIALS` or `opts[:credentials]`)
  """

  @metadata_token "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"
  @metadata_project "http://metadata.google.internal/computeMetadata/v1/project/project-id"
  @token_uri "https://oauth2.googleapis.com/token"
  @scope "https://www.googleapis.com/auth/compute"

  def access_token(opts) when is_list(opts) do
    cond do
      is_binary(opts[:token]) and opts[:token] != "" ->
        {:ok, opts[:token]}

      is_binary(System.get_env("GOOGLE_ACCESS_TOKEN")) ->
        {:ok, System.get_env("GOOGLE_ACCESS_TOKEN")}

      is_binary(System.get_env("CLOUDSDK_AUTH_ACCESS_TOKEN")) ->
        {:ok, System.get_env("CLOUDSDK_AUTH_ACCESS_TOKEN")}

      is_function(opts[:http], 3) ->
        :error

      true ->
        metadata_token() || gcloud_token() || service_account_token(opts)
    end
  end

  def project(opts) when is_list(opts) do
    opts[:project] ||
      System.get_env("GOOGLE_CLOUD_PROJECT") ||
      System.get_env("GCLOUD_PROJECT") ||
      System.get_env("GCP_PROJECT") ||
      metadata_project()
  end

  defp metadata_token do
    case metadata_get(@metadata_token) do
      {:ok, %{status: 200, body: %{"access_token" => token}}} -> {:ok, token}
      _ -> nil
    end
  end

  defp metadata_project do
    case metadata_get(@metadata_project) do
      {:ok, %{status: 200, body: body}} when is_binary(body) -> String.trim(body)
      _ -> nil
    end
  end

  defp metadata_get(url) do
    Crucible.HTTP.get(url,
      headers: [{"metadata-flavor", "Google"}],
      receive_timeout: 400,
      retries: 0
    )
  rescue
    _ -> :error
  end

  defp gcloud_token do
    case System.cmd("gcloud", ["auth", "print-access-token"], stderr_to_stdout: true) do
      {out, 0} -> {:ok, String.trim(out)}
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp service_account_token(opts) do
    path = opts[:credentials] || System.get_env("GOOGLE_APPLICATION_CREDENTIALS")

    with true <- is_binary(path),
         {:ok, raw} <- File.read(path),
         {:ok, creds} <- Jason.decode(raw),
         {:ok, jwt} <- jwt(creds),
         {:ok, %{"access_token" => token}} <-
           Crucible.HTTP.post(@token_uri,
             headers: [{"content-type", "application/x-www-form-urlencoded"}],
             body:
               URI.encode_query(%{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
                 "assertion" => jwt
               }),
             retries: 0
           ) do
      {:ok, token}
    else
      _ -> nil
    end
  end

  defp jwt(%{"client_email" => email, "private_key" => pem}) do
    now = System.system_time(:second)

    header =
      %{"alg" => "RS256", "typ" => "JWT"}
      |> Jason.encode!()
      |> urlencode()

    payload =
      %{
        "iss" => email,
        "sub" => email,
        "scope" => @scope,
        "aud" => @token_uri,
        "iat" => now,
        "exp" => now + 3600
      }
      |> Jason.encode!()
      |> urlencode()

    signing_input = header <> "." <> payload

    with {:ok, key} <- rsa_key(pem),
         sig when is_binary(sig) <- :public_key.sign(signing_input, :sha256, key) do
      {:ok, signing_input <> "." <> urlencode(sig)}
    end
  end

  defp jwt(_), do: :error

  defp rsa_key(pem) do
    case :public_key.pem_decode(pem) do
      [entry | _] -> {:ok, :public_key.pem_entry_decode(entry)}
      _ -> :error
    end
  end

  defp urlencode(bin) do
    bin
    |> Base.encode64()
    |> String.replace("+", "-")
    |> String.replace("/", "_")
    |> String.replace("=", "")
  end
end
