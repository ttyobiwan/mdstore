defmodule Mdstore.Cache.Behavior do
  @moduledoc """
  Defines the behavior for cache implementations.

  This behavior provides a contract for cache modules that need to implement
  basic get and set operations with optional TTL (time-to-live) support.
  """

  @doc """
  Retrieves a value from the cache by key.

  ## Parameters
  - `key`: The cache key as a string

  ## Returns
  - `{:ok, value}` if cached value was found
  - `{:ok, nil}` if the key doesn't exist or has expired
  - `{:error, reason}` if the operation fails
  """
  @callback get(key :: String.t()) :: {:ok, any() | nil} | {:error, any()}

  @doc """
  Stores a value in the cache with the given key.

  ## Parameters
  - `key`: The cache key as a string
  - `value`: The value to store

  ## Returns
  - `:ok` on successful storage
  - `{:error, reason}` if the operation fails
  """
  @callback set(key :: String.t(), value :: any()) :: :ok | {:error, any()}

  @doc """
  Stores a value in the cache with the given key and TTL.

  ## Parameters
  - `key`: The cache key as a string
  - `value`: The value to store
  - `ttl`: Time-to-live in seconds (positive integer)

  ## Returns
  - `:ok` on successful storage
  - `{:error, reason}` if the operation fails
  """
  @callback set(key :: String.t(), value :: any(), ttl :: pos_integer()) :: :ok | {:error, any()}
end
