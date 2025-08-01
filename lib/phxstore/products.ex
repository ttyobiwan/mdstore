defmodule Phxstore.Products do
  alias Phxstore.Repo
  alias Phxstore.Products.Product

  @doc """
  Creates a new product.
  """
  def create_product(attrs) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update product.
  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Get product by id.
  """
  def get_product(id) do
    Product
    |> Repo.get(id)
    |> Repo.preload(:front_image)
  end

  @doc """
  Get all products.
  """
  def get_all_products() do
    Repo.all(Product)
  end
end
