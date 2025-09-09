defmodule Mdstore.Carts do
  @moduledoc """
  Context module for managing shopping carts and cart items.

  Provides functions for creating carts, adding products to carts,
  and handling cart-related operations.
  """

  alias Mdstore.Carts.CartItem
  alias Mdstore.Carts.Cart
  alias Mdstore.Repo
  import Ecto.Query

  @doc """
  Gets an existing cart for a user.

  ## Parameters
  - `user` - The user struct to get a cart for

  ## Returns
  - `{:ok, cart}` - The existing and open cart
  - `nil` - If cart does not exist
  """
  def get_cart(user) do
    Repo.one(
      from c in Cart,
        where: c.user_id == ^user.id and c.is_open == true,
        limit: 1,
        preload: [:products, products: :front_image]
    )
  end

  @doc """
  Creates a new cart.

  ## Parameters
  - `attrs` - A map of attributes for the cart

  ## Returns
  - `{:ok, cart}` - If the cart was successfully created
  - `{:error, changeset}` - If validation fails
  """
  def create_cart(attrs) do
    %Cart{}
    |> Cart.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets an existing cart for a user or creates a new one if none exists.

  ## Parameters
  - `user` - The user struct to get or create a cart for

  ## Returns
  - `{:ok, cart}` - The existing or newly created cart
  - `{:error, changeset}` - If cart creation fails
  """
  def get_or_create_cart(user) do
    case get_cart(user) do
      nil -> create_cart(%{user_id: user.id})
      cart -> {:ok, cart}
    end
  end

  @doc """
  Adds a product to a cart with the specified quantity.

  ## Parameters
  - `cart` - The cart to add the product to
  - `product` - The product to add
  - `quantity` - The quantity to add (defaults to 1)

  ## Returns
  - `:ok` - If the product was successfully added
  - `{:error, :product_already_in_cart}` - If the product is already in the cart
  - `{:error, changeset}` - If validation fails
  """
  def add_to_cart(cart, product, quantity \\ 1) do
    case %CartItem{}
         |> CartItem.changeset(%{
           cart_id: cart.id,
           product_id: product.id,
           quantity: quantity
         })
         |> Repo.insert() do
      {:ok, _item} ->
        :ok

      {:error, %Ecto.Changeset{} = changeset} ->
        if unique_constraint_error?(changeset, [:cart_id, :product_id]) do
          {:error, :product_already_in_cart}
        else
          {:error, changeset}
        end
    end
  end

  @doc """
  Removes a product from a cart.

  ## Parameters
  - `cart` - The cart to remove the product from
  - `product` - The product to remove

  ## Returns
  - `nil` - Always returns nil after deletion
  """
  def remove_from_cart(cart, product) do
    Repo.delete_all(
      from i in CartItem, where: i.cart_id == ^cart.id and i.product_id == ^product.id
    )

    nil
  end

  @doc """
  Closes a cart by setting is_open to false.

  ## Parameters
  - `cart` - The cart to close

  ## Returns
  - `{:ok, cart}` - If the cart was successfully closed
  - `{:error, changeset}` - If validation fails
  """
  def close_cart(cart) do
    cart
    |> Cart.open_changeset(%{is_open: false})
    |> Repo.update()
  end

  # Check if changeset contains unique constraint error for any of the given fields
  defp unique_constraint_error?(changeset, fields) do
    Enum.any?(changeset.errors, fn {field, {_message, opts}} ->
      field in fields and opts[:constraint] == :unique
    end)
  end
end
