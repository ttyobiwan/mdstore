defmodule Mdstore.Carts.Cart do
  @moduledoc """
  Cart represents a collection of items that a user placed into a shopping cart.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "carts" do
    field :is_open, :boolean, default: true

    belongs_to :user, Mdstore.Accounts.User
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

  @doc false
  def open_changeset(cart, attrs) do
    cart
    |> cast(attrs, [:is_open])
    |> validate_required([:is_open])
  end
end
