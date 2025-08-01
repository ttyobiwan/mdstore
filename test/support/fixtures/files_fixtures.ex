defmodule Phxstore.FilesFixtures do
  alias Phxstore.Images

  def unique_image_name, do: "image#{System.unique_integer()}.jpg"

  def valid_image_attributes(attrs \\ %{}) do
    default_name = unique_image_name()

    Enum.into(attrs, %{
      path: default_name,
      id: Ecto.UUID.generate(),
      filename: default_name
    })
  end

  def image_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, valid_image_attributes())

    {:ok, image} =
      Images.create_image(
        attrs.path,
        attrs.id,
        attrs.filename
      )

    image
  end
end
