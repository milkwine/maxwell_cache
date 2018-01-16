# MaxwellCache

Maxwell middleware to cache success response.

## Installation

Add `maxwell_cache` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:maxwell_cache, "~> 0.0.1"}
  ]
end
```

## Usage

From official example here:

```elixir
defmodule GitHubClient do
  # Generates `get/1`, `get!/1`, `patch/1`, `patch!/1` public functions
  # You can omit the list and functions for all HTTP methods will be generated
  use Maxwell.Builder, ~w(get patch)a

  # For a complete list of middlewares, see the docs
  middleware Maxwell.Middleware.BaseUrl, "https://api.github.com"
  middleware Maxwell.Middleware.Headers, %{"content-type" => "application/vnd.github.v3+json", "user-agent" => "zhongwenool"}
  middleware Maxwell.Middleware.Opts,    connect_timeout: 3000

  # Need to run before decode response
  middleware Maxwell.Middleware.Cache,   ttl: :timer.minutes(1), namespace: "githubclient"
  middleware Maxwell.Middleware.Json
  middleware Maxwell.Middleware.Logger

  # adapter can be omitted, and the default will be used (currently :ibrowse)
  adapter Maxwell.Adapter.Hackney

  # List public repositories for the specified user.
  def user_repos(username) do
    "/users/#{username}/repos"
    |> new()
    |> get()
  end

  # Edit owner repositories
  def edit_repo_desc(owner, repo, name, desc) do
    "/repos/#{owner}/#{repo}"
    |> new()
    |> put_req_body(%{name: name, description: desc})
    |> patch()
  end
end
```
