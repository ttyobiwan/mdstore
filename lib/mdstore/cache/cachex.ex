defmodule Mdstore.Cache.Cachex do
  @moduledoc """
  A Cachex-based cache implementation.

  ## Configuration

  The Redis connection is configured through the application environment:

      config :mdstore, :cachex, name: :some_cache
  """

  require Logger

  @behaviour Mdstore.Cache.Behavior

  @name Application.compile_env(:mdstore, :cachex)[:name]

  @default_ttl 3600

  @doc """
  Retrieves a value from the cache by key.

  The stored binary data is automatically deserialized back to its original Elixir term.

  ## Parameters

    * `key` - The cache key to retrieve

  ## Returns

    * `{:ok, value}` - The cached value if found
    * `{:ok, nil}` - If the key is not found in the cache
    * `{:error, reason}` - If an error occurred during retrieval

  ## Examples

      iex> Mdstore.Cache.Cachex.get("my_key")
      {:ok, %{data: "some_value"}}

      iex> Mdstore.Cache.Cachex.get("non_existent_key")
      {:ok, nil}
  """
  @impl true
  def get(key) do
    case Cachex.get(@name, key) do
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
  Stores a value in the cache with the given key and TTL.

  The value is automatically serialized using Erlang's term-to-binary format
  before being stored in the cache.

  ## Parameters

    * `key` - The cache key to store under
    * `value` - The Elixir term to cache
    * `ttl` - Time-to-live in seconds (defaults to #{@default_ttl} seconds)

  ## Returns

    * `{:ok, true}` - If the value was successfully stored
    * `{:error, reason}` - If an error occurred during storage

  ## Examples

      iex> Mdstore.Cache.Cachex.set("my_key", %{data: "value"})
      {:ok, true}

      iex> Mdstore.Cache.Cachex.set("my_key", %{data: "value"}, 7200)
      {:ok, true}
  """
  @impl true
  def set(key, value, ttl \\ @default_ttl) do
    serialized = :erlang.term_to_binary(value)
    Cachex.put(@name, key, serialized, expire: ttl)
  end

  @doc """
  Returns the child specification for starting this cache under a supervisor.

  The cache is started as a Cachex process with the configured name.

  ## Returns

  A child specification tuple suitable for use in a supervisor's children list.
  """
  def child_spec(), do: {Cachex, [@name]}
end
