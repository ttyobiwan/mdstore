defmodule Mdstore.Carts.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field :quantity, :integer, default: 1
    field :cart_id, :id
    field :product_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:quantity, :cart_id, :product_id])
    |> validate_required([:quantity, :cart_id, :product_id])
    |> unique_constraint([:cart_id, :product_id],
      name: :cart_items_cart_id_product_id_index,
      message: "Product already added to the cart"
    )
  end
end
