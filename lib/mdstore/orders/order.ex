defmodule Mdstore.Orders.Order do
  @moduledoc """
  Order represents an order placed by a user.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field :status, Ecto.Enum, values: [:created, :paid, :canceled]
    field :user_id, :id
    field :checkout_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:status, :user_id, :checkout_id])
    |> validate_required([:status, :user_id, :checkout_id])
  end

  @doc false
  def status_changeset(order, attrs) do
    order
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
