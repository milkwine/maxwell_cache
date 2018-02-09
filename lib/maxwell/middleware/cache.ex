defmodule Maxwell.Middleware.Cache do
  use Maxwell.Middleware
  alias Maxwell.Conn

  @default_namespace "default"
  @pri_from_cache    :MIDDLE_CACHE_from_cache
  @pri_from_source   :MIDDLE_CACHE_from_source
  @pri_ttl           :MIDDLE_CACHE_ttl

  def init(opts) do
    namespace = opts[:namespace] || @default_namespace
    hash_func = opts[:hash_func] || &__MODULE__.default_hash_func/1
    ttl       = opts[:ttl]
    {namespace, hash_func, ttl}
  end

  @doc """
  Make this requrest get response from cache first.
  """
  def from_cache(%Maxwell.Conn{} = conn) do
    Maxwell.Conn.put_private(conn, @pri_from_cache, true)
  end

  @doc """
  Make this requrest get response from remote server and set cache.
  """
  def from_source(%Maxwell.Conn{} = conn) do
    Maxwell.Conn.put_private(conn, @pri_from_source, true)
  end

  @doc """
  Set ttl to cache the request.
  """
  def set_ttl(%Maxwell.Conn{} = conn, ttl) do
    Maxwell.Conn.put_private(conn, @pri_ttl, ttl)
  end

  @doc """
  Default hash function. Generate a key from `conn` to get/store response from/to cache.
  Can be replaced by user defined function by pass `:hash_func` to `init/1`.
  """
  def default_hash_func(%Maxwell.Conn{} = conn) do
    query_string = conn.query_string |> Maxwell.Query.encode
    headers      = conn.req_headers  |> Maxwell.Query.encode
    body         = conn.req_body     |> :erlang.phash2

    "#{conn.method}|#{conn.url}|#{conn.path}|#{query_string}|#{headers}|#{body}"
  end


  def call(conn = %Maxwell.Conn{private: %{@pri_from_cache => true}}, next, {namespace, hash_func, ttl}) do

    ttl = Map.get(conn.private, @pri_ttl, ttl)
    key = pk(conn, namespace, hash_func)

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

  def call(conn = %Maxwell.Conn{private: %{@pri_from_source => true}}, next, {namespace, hash_func, ttl}) do

    ttl = Map.get(conn.private, @pri_ttl, ttl)
    key = pk(conn, namespace, hash_func)

    conn
    |> next.()
    |> set_cache(key, ttl)

  end

  def call(conn = %Maxwell.Conn{}, next, _opts), do: next.(conn)

  defp pk(conn, namespace, hash_func), do: namespace <> "#" <> hash_func.(conn)

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
