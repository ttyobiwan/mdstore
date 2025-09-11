defmodule Mdstore.Cache.Redis do
  @moduledoc """
  Redis cache backend implementation.

  ## Configuration

  The Redis connection is configured through the application environment:

      config :mdstore, :redis,
        name: :redis_cache,
        host: "localhost",
        port: 6379
  """

  require Logger

  @behaviour Mdstore.Cache.Behavior

  @name Application.compile_env(:mdstore, :redis)[:name]

  @default_ttl 3600

  @doc """
  Retrieves a value from the Redis cache by key.

  ## Parameters

    * `key` - The cache key to retrieve

  ## Returns

    * `{:ok, value}` - Successfully retrieved the cached value (nil if key doesn't exist)
    * `{:error, reason}` - An error occurred while retrieving the value

  ## Examples

      iex> Mdstore.Cache.Redis.get("existing_key")
      {:ok, "cached_value"}

      iex> Mdstore.Cache.Redis.get("missing_key")
      {:ok, nil}
  """
  @impl true
  def get(key) do
    case Redix.command(@name, ["GET", key]) do
      {:ok, nil} ->
        Logger.debug("Cache missed for #{inspect(key)}")
        {:ok, nil}

      {:ok, data} ->
        {:ok, :erlang.binary_to_term(data)}

      {:error, reason} ->
        Logger.debug("Error reading key #{inspect(key)} from cache: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Stores a value in the Redis cache with an optional TTL.

  The value is serialized using Erlang's term_to_binary before storage.

  ## Parameters

    * `key` - The cache key to store the value under
    * `value` - The value to cache (any Erlang term)
    * `ttl` - Time to live in seconds (defaults to #{@default_ttl} seconds)

  ## Returns

    * `{:ok, "OK"}` - Successfully stored the value
    * `{:error, reason}` - An error occurred while storing the value

  ## Examples

      iex> Mdstore.Cache.Redis.set("my_key", %{data: "value"})
      {:ok, "OK"}

      iex> Mdstore.Cache.Redis.set("temp_key", "temp_value", 60)
      {:ok, "OK"}
  """
  @impl true
  def set(key, value, ttl \\ @default_ttl) do
    serialized = :erlang.term_to_binary(value)
    Redix.command(@name, ["SETEX", key, ttl, serialized])
  end

  @doc """
  Returns the child specification for starting the Redis connection.

  This is used when adding the Redis cache to a supervision tree.
  """
  def child_spec, do: {Redix, Application.get_env(:mdstore, :redis)}
end
