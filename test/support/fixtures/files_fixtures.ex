defmodule Phxstore.FilesFixtures do
  alias Phxstore.Images

  def unique_image_name, do: "image#{System.unique_integer()}.jpg"

  def valid_image_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_image_name()
    })
  end

  def image_fixture(attrs \\ %{}) do
    {:ok, image} = attrs |> valid_image_attributes() |> Images.create_image()
    image
  end
end
