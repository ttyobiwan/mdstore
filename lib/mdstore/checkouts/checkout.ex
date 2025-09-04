defmodule Mdstore.Checkouts.Checkout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "checkouts" do
    field :status, Ecto.Enum, values: [:started, :submitted, :successful, :failed]
    field :total, :float
    field :user_id, :id
    field :product_id, :id
    field :cart_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(checkout, attrs) do
    checkout
    |> cast(attrs, [:status, :total, :user_id, :product_id, :cart_id])
    |> validate_required([:status, :user_id])
    |> unique_constraint(:cart_id)
  end

  @doc false
  def status_changeset(checkout, attrs) do
    checkout
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
