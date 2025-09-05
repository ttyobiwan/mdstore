defmodule Mdstore.Carts.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  schema "carts" do
    field :user_id, :id

    has_many :items, Mdstore.Carts.CartItem
    has_many :products, through: [:items, :product]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cart, attrs) do
    cart
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end
end
