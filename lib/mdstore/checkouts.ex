defmodule Mdstore.Checkouts do
  @moduledoc """
  Context module for managing checkout operations.

  Provides functions to create and manage checkout records in the system.
  """

  alias Mdstore.Checkouts.Checkout
  alias Mdstore.Repo

  @doc """
  Creates a new checkout with the given attributes.

  ## Parameters
  - `attrs` - A map of attributes for the checkout

  ## Returns
  - `{:ok, checkout}` on success
  - `{:error, changeset}` on failure
  """
  def create_checkout(attrs) do
    %Checkout{}
    |> Checkout.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the status of an existing checkout.

  ## Parameters
  - `checkout` - The checkout struct to update
  - `status` - The new status value

  ## Returns
  - `{:ok, checkout}` on success
  - `{:error, changeset}` on failure
  """
  def update_status(%Checkout{} = checkout, status) do
    checkout
    |> Checkout.status_changeset(%{status: status})
    |> Repo.update()
  end
end
