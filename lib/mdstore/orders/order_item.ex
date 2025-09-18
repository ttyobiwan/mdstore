defmodule Mdstore.Orders.OrderItem do
  @moduledoc """
  OrderItem represents a product inside an order.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "order_items" do
    field :quantity, :integer
    field :order_id, :id
    field :product_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:quantity, :order_id, :product_id])
    |> validate_required([:quantity, :order_id, :product_id])
  end
end
