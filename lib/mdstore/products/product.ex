defmodule Mdstore.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :description, :string
    field :quantity, :integer
    field :price, :float

    belongs_to :front_image, Mdstore.Files.Image

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description, :quantity, :price, :front_image_id])
    |> validate_required([:name, :description, :quantity, :price, :front_image_id])
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> validate_number(:price, greater_than_or_equal_to: 0)
  end
end
