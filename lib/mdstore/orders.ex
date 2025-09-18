defmodule Mdstore.Orders do
  @moduledoc """
  Context module for managing orders.
  """

  alias Ecto.Multi
  alias Mdstore.Orders.OrderItem
  alias Mdstore.Accounts.User
  alias Mdstore.Checkouts.Checkout
  alias Mdstore.Checkouts
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
  Retrieves an order by its ID.

  ## Parameters
    - id: The ID of the order to retrieve

  ## Returns
    - `%Order{}` struct
    - `nil` if no order exists with the given ID

  ## Examples
      iex> get_order(123)
      %Order{id: 123, checkout: %Checkout{cart: %Cart{}}}

      iex> get_order(999)
      nil
  """
  def get_order(id) do
    Repo.get(Order, id) |> Repo.preload(checkout: :cart)
  end

  @doc """
  Creates a new order item with the given attributes.

  ## Parameters
    - attrs: A map of attributes for the order item

  ## Returns
    - `{:ok, %OrderItem{}}` on success
    - `{:error, %Ecto.Changeset{}}` on failure
  """
  def create_order_item(attrs) do
    %OrderItem{}
    |> OrderItem.changeset(attrs)
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
  def update_order_status(%Order{} = order, status) when order.status == status do
    {:ok, order}
  end

  def update_order_status(%Order{} = order, status) do
    order
    |> Order.status_changeset(%{status: status})
    |> Repo.update()
  end

  @doc """
  Places an order for the items.

  Atomically handles all logic behind placing an order:
  - Updating the checkout status
  - Creating a new order
  - Creating order items for all provided items

  ## Parameters
    - checkout: A `%Checkout{}` struct representing the checkout to be processed
    - user: A `%User{}` struct representing the user placing the order
    - items: A list of items to be included in the order. Each item should have
             `:quantity` and `:product` fields

  ## Returns
    - `{:ok, %Order{}}` on successful order placement
    - `{:error, :empty_items}` when items list is empty
    - `{:error, :invalid_count}` when not all order items could be created
    - `{:error, %Ecto.Changeset{}}` on validation failures
    - `{:error, reason}` for other transaction failures

  ## Examples
      iex> place_order(checkout, user, [%{quantity: 2, product: product}])
      {:ok, %Order{}}

      iex> place_order(checkout, user, [])
      {:error, :empty_items}
  """
  def place_order(%Checkout{} = _checkout, %User{} = _user, []) do
    {:error, :empty_items}
  end

  def place_order(%Checkout{} = checkout, %User{} = user, items) do
    result =
      Multi.new()
      |> Multi.run(:checkout, fn _repo, _ops ->
        Checkouts.update_status(checkout, :submitted)
      end)
      |> Multi.run(:order, fn _repo, _ops ->
        create_order(%{
          status: :created,
          user_id: user.id,
          checkout_id: checkout.id
        })
      end)
      |> Multi.run(:order_items, fn _repo, %{order: order} ->
        case bulk_create_order_items(order, items) do
          {count, _entries} when count != length(items) ->
            {:error, :invalid_count}

          {_count, entries} ->
            {:ok, entries}
        end
      end)
      |> Repo.transaction()

    case result do
      {:ok, result} -> {:ok, result.order}
      {:error, reason} -> {:error, reason}
    end
  end

  # Bulk insert all items as order items
  defp bulk_create_order_items(order, items) do
    now = DateTime.utc_now(:second)

    items
    |> Enum.map(
      &%{
        quantity: &1.quantity,
        order_id: order.id,
        product_id: &1.product.id,
        inserted_at: now,
        updated_at: now
      }
    )
    |> then(&Repo.insert_all(OrderItem, &1))
  end

  @doc """
  Enqueues a job for processing payment success.

  ## Parameters
    - order: An Order struct representing the order that had a successful payment

  ## Returns
    - `{:ok, %Oban.Job{}}` on successful job enqueue
    - `{:error, %Ecto.Changeset{}}` on failure
  """
  def handle_successful_payment(%Order{} = order) do
    %{order_id: order.id}
    |> Mdstore.Workers.PaymentSuccess.new()
    |> Oban.insert()
  end
end
