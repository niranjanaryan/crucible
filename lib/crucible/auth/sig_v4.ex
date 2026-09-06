defmodule Crucible.Auth.SigV4 do
  @moduledoc """
  AWS Signature Version 4 for REST drivers (`ecs`, `lightsail`, …).

  Keys: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, optional `AWS_REGION`.
  """

  def sign(method, url, headers, body, opts) when is_list(opts) do
    uri = URI.parse(to_string(url))
    now = Keyword.get(opts, :datetime) || DateTime.utc_now()
    amz_date = datetime_iso(now)
    datestamp = String.slice(amz_date, 0, 8)
    region = Keyword.get(opts, :region, "us-east-1")
    service = Keyword.get(opts, :service, "execute-api")
    access = Keyword.fetch!(opts, :access_key)
    secret = Keyword.fetch!(opts, :secret_key)
    body = body || ""
    payload_hash = sha256_hex(body)

    headers =
      headers
      |> drop_ci(["authorization", "x-amz-date", "x-amz-content-sha256", "host"])
      |> Kernel.++([
        {"host", host_header(uri)},
        {"x-amz-date", amz_date},
        {"x-amz-content-sha256", payload_hash}
      ])

    signed_names =
      headers
      |> Enum.map(fn {k, _} -> String.downcase(k) end)
      |> Enum.sort()
      |> Enum.uniq()

    canonical_headers =
      signed_names
      |> Enum.map(fn name ->
        values =
          headers
          |> Enum.filter(fn {k, _} -> String.downcase(k) == name end)
          |> Enum.map(fn {_, v} -> String.trim(to_string(v)) end)
          |> Enum.join(",")

        "#{name}:#{values}\n"
      end)
      |> IO.iodata_to_binary()

    signed_headers = Enum.join(signed_names, ";")
    canonical_query = canonical_query(uri.query)
    canonical_uri = uri.path || "/"
    method_s = method |> to_string() |> String.upcase()

    canonical_request =
      [
        method_s,
        canonical_uri,
        canonical_query,
        canonical_headers,
        signed_headers,
        payload_hash
      ]
      |> Enum.join("\n")

    credential_scope = "#{datestamp}/#{region}/#{service}/aws4_request"

    string_to_sign =
      [
        "AWS4-HMAC-SHA256",
        amz_date,
        credential_scope,
        sha256_hex(canonical_request)
      ]
      |> Enum.join("\n")

    signature =
      secret
      |> signing_key(datestamp, region, service)
      |> hmac(string_to_sign)
      |> Base.encode16(case: :lower)

    auth =
      "AWS4-HMAC-SHA256 Credential=#{access}/#{credential_scope}, SignedHeaders=#{signed_headers}, Signature=#{signature}"

    [{"authorization", auth} | headers]
  end

  def credentials(opts) when is_list(opts) do
    access = Keyword.get(opts, :access_key) || System.get_env("AWS_ACCESS_KEY_ID")
    secret = Keyword.get(opts, :secret_key) || System.get_env("AWS_SECRET_ACCESS_KEY")
    region = Keyword.get(opts, :region) || System.get_env("AWS_REGION") || "us-east-1"

    if is_binary(access) and access != "" and is_binary(secret) and secret != "" do
      {:ok, access, secret, region}
    else
      :error
    end
  end

  defp signing_key(secret, datestamp, region, service) do
    ("AWS4" <> secret)
    |> hmac(datestamp)
    |> hmac(region)
    |> hmac(service)
    |> hmac("aws4_request")
  end

  defp hmac(key, data) do
    :crypto.mac(:hmac, :sha256, key, data)
  end

  defp sha256_hex(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  defp canonical_query(nil), do: ""

  defp canonical_query(q) do
    q
    |> URI.decode_query()
    |> Enum.sort_by(fn {k, _} -> k end)
    |> URI.encode_query()
  end

  defp host_header(%URI{host: host, port: port, scheme: scheme}) do
    cond do
      scheme == "https" and port in [nil, 443] -> host
      scheme == "http" and port in [nil, 80] -> host
      is_integer(port) -> "#{host}:#{port}"
      true -> host
    end
  end

  defp drop_ci(headers, names) do
    names = MapSet.new(names)

    Enum.reject(headers, fn {k, _} ->
      MapSet.member?(names, String.downcase(to_string(k)))
    end)
  end

  defp datetime_iso(%DateTime{} = dt) do
    dt
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601(:basic)
  end
end
