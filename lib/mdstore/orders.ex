defmodule Mdstore.Orders do
  @moduledoc """
  Context module for managing orders.
  """

  alias Mdstore.Repo
  alias Mdstore.Orders.Order

  @doc """
  Creates a new order with the given attributes.

  ## Parameters
    - attrs: A map of attributes for the order

  ## Returns
    - `{:ok, %Order{}}` on success
    - `{:error, %Ecto.Changeset{}}` on failure
  """
  def create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the status of an existing order.

  ## Parameters
    - order: An Order struct
    - status: The new status value

  ## Returns
    - `{:ok, %Order{}}` on success
    - `{:error, %Ecto.Changeset{}}` on failure
  """
  def update_order_status(%Order{} = order, status) do
    order
    |> Order.status_changeset(%{status: status})
    |> Repo.update()
  end
end
