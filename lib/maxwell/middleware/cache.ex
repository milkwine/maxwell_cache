defmodule Maxwell.Middleware.Cache do
  use Maxwell.Middleware
  alias Maxwell.Conn

  @default_namespace "default"

  def init(opts) do
    namespace = opts[:namespace] || @default_namespace
    hash_func = opts[:hash_func] || &__MODULE__.default_hash_func/1
    ttl       = opts[:ttl]
    {namespace, hash_func, ttl}
  end

  def default_hash_func(%Maxwell.Conn{} = conn) do
    query_string = conn.query_string |> Maxwell.Query.encode
    headers      = conn.req_headers  |> Maxwell.Query.encode
    body         = conn.req_body     |> :erlang.phash2

    "#{conn.method}|#{conn.url}|#{conn.path}|#{query_string}|#{headers}|#{body}"
  end

  def call(conn, next, {namespace, hash_func, ttl}) do
    key = namespace <> "#" <> hash_func.(conn)
    case Cachex.get(:maxwell_cache_cachex, key) do
      {:ok, {resp_body, resp_headers}} ->
        %{conn | status:        200,
                 resp_headers:  resp_headers,
                 resp_body:     resp_body,
                 state:         :sent,
                 req_body:      nil}
      _ -> 
        conn
        |> next.()
        |> set_cache(key, ttl)
    end
  end

  defp set_cache(conn=%Maxwell.Conn{status: status}, key, ttl) when status == 200 do
    value = {conn.resp_body, conn.resp_headers}
    ret = Cachex.set(:maxwell_cache_cachex, key, value, ttl: ttl, async: true)
    case ret do
      {:ok, true} -> conn
      _           -> {:error, :set_cache_error, conn}
    end
  end

  defp set_cache(conn, _key, _ttl), do: conn

end
