defmodule Mdstore.ProductsFixtures do
  alias Mdstore.FilesFixtures
  alias Mdstore.Products

  def unique_product_name, do: "product #{System.unique_integer()}"

  def valid_product_attributes(attrs \\ %{}) do
    attrs
    |> Map.put_new_lazy(:front_image_id, fn -> FilesFixtures.image_fixture().id end)
    |> Enum.into(%{
      name: unique_product_name(),
      description: "test description",
      quantity: 1,
      price: 1.0
    })
  end

  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> valid_product_attributes()
      |> Products.create_product()

    Mdstore.Repo.preload(product, :front_image)
  end
end
