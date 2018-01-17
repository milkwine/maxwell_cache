defmodule MaxwellCache.Application do

  use Application

  @default_limit %Cachex.Limit{limit: 2000, reclaim: 0.1}
  @default_ttl :timer.seconds(10)

  def start(_type, _args) do
    import Supervisor.Spec

    limit       = Application.get_env(:maxwell_cache, :limit, @default_limit)
    default_ttl = Application.get_env(:maxwell_cache, :default_ttl, @default_ttl)

    children = [
      worker(Cachex, [:maxwell_cache_cachex, [limit: limit, default_ttl: default_ttl]]),
    ]

    opts = [strategy: :one_for_one, name: MaxwellCache.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
