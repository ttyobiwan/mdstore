defmodule Mdstore.Checkouts.Checkout do
  @moduledoc """
  Checkout represents progress in the process of purchasing a product or paying for shopping cart.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "checkouts" do
    field :status, Ecto.Enum, values: [:started, :submitted, :successful, :failed]
    field :total, :float

    belongs_to :user, Mdstore.Accounts.User
    belongs_to :product, Mdstore.Products.Product
    belongs_to :cart, Mdstore.Carts.Cart

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(checkout, attrs) do
    checkout
    |> cast(attrs, [:status, :total, :user_id, :product_id, :cart_id])
    |> validate_required([:status, :total, :user_id])
    |> validate_product_or_cart()
    |> unique_constraint(:cart_id)
  end

  @doc false
  def status_changeset(checkout, attrs) do
    checkout
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  # Validate that either product or cart is present
  defp validate_product_or_cart(changeset) do
    product_id = get_field(changeset, :product_id)
    cart_id = get_field(changeset, :cart_id)

    cond do
      is_nil(product_id) and is_nil(cart_id) ->
        changeset
        |> add_error(:product_id, "either product or cart must be present")
        |> add_error(:cart_id, "either product or cart must be present")

      not is_nil(product_id) and not is_nil(cart_id) ->
        changeset
        |> add_error(:product_id, "cannot have both product and cart")
        |> add_error(:cart_id, "cannot have both product and cart")

      true ->
        changeset
    end
  end
end
