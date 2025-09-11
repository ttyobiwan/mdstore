defmodule Mdstore.Cache do
  @moduledoc """
  A cache module that delegates operations to a configurable backend.

  The backend is configured via the `:cache_backend` application environment
  variable for the `:mdstore` application.
  """

  @backend Application.compile_env(:mdstore, :cache_backend)

  defdelegate get(key), to: @backend
  defdelegate set(key, value), to: @backend
  defdelegate set(key, value, ttl), to: @backend
end
