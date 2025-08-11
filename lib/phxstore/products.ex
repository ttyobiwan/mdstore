defmodule Phxstore.Products do
  alias Phxstore.Images
  alias Phxstore.Repo
  alias Phxstore.Products.Product
  alias Ecto.Multi
  import Ecto.Query

  @doc """
  Creates a new product.
  """
  def create_product(attrs) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product.
  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets product by id.
  """
  def get_product(id) do
    Product
    |> Repo.get(id)
    |> Repo.preload(:front_image)
  end

  @doc """
  Gets all products.
  Paginates them based on the options passed.
  """
  def get_all_products(opts \\ []) do
    page = String.to_integer(opts[:page] || "1")
    per_page = String.to_integer(opts[:per_page] || "10")
    offset = (page - 1) * per_page

    from(p in Product,
      limit: ^per_page,
      offset: ^offset,
      preload: :front_image
    )
    |> Repo.all()
  end

  @doc """
  Counts the number of products.
  """
  def count_products() do
    Repo.aggregate(Product, :count)
  end

  @doc """
  Deletes a product.
  Also deletes all related images.
  """
  def delete_product(%Product{} = product) do
    Multi.new()
    |> Multi.delete(:product, product)
    |> Multi.run(:delete_image, fn _repo, _changes ->
      Images.delete_image(product.front_image)
    end)
    |> Repo.transaction()
  end
end
