defmodule CacheTest do

  use ExUnit.Case, async: false
  import Maxwell.Conn

  defmodule Client do

    use Maxwell.Builder
    import Maxwell.Middleware.Cache, only: [from_cache: 1, from_source: 1, set_ttl: 2]

    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts,    [connect_timeout: 6000]
    middleware Maxwell.Middleware.Cache,   ttl: :timer.minutes(1), namespace: "httpbin"
    middleware Maxwell.Middleware.Json

    def get_uuid do
      "/uuid"
      |> new()
      |> get!
      |> get_resp_body
    end

    def get_uuid_from_source do
      "/uuid"
      |> new()
      |> from_source()
      |> get!
      |> get_resp_body
    end

    def get_uuid_from_cache do
      "/uuid"
      |> new()
      |> from_cache()
      |> set_ttl(:timer.seconds(4))
      |> get!
      |> get_resp_body
    end

  end

  test "normal request" do
    resp1 = Client.get_uuid
    resp2 = Client.get_uuid
    assert is_map(resp1)
    assert is_map(resp2)
    assert resp1 != resp2
  end

  test "request from cache" do
    resp1 = Client.get_uuid_from_cache
    resp2 = Client.get_uuid_from_cache

    Process.sleep(:timer.seconds(6))

    resp3 = Client.get_uuid_from_cache

    assert resp1 == resp2
    assert resp2 != resp3
  end

  test "request from source" do
    resp1 = Client.get_uuid_from_cache
    resp2 = Client.get_uuid_from_source
    resp3 = Client.get_uuid_from_cache

    assert resp1 != resp2
    assert resp2 == resp3
  end

end
