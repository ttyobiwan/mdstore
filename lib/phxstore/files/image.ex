defmodule Phxstore.Files.Image do
  use Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    # todo: validate size, extension
    image
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
