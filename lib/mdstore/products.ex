defmodule Mdstore.Products do
  @moduledoc """
  The products context.
  """

  alias Mdstore.Images
  alias Mdstore.Repo
  alias Mdstore.Products.Product
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
  Gets all products, based on the passed query and pagination.
  """
  def get_all_products(page, per_page) do
    offset = (page - 1) * per_page

    Repo.all(
      from(p in Product,
        limit: ^per_page,
        offset: ^offset,
        preload: :front_image
      )
    )
  end

  def get_all_products(query, page, per_page) when query in ["", nil] do
    get_all_products(page, per_page)
  end

  def get_all_products(query, page, per_page) do
    offset = (page - 1) * per_page

    Repo.all(
      from(p in Product,
        limit: ^per_page,
        offset: ^offset,
        where: ilike(p.name, ^"%#{query}%"),
        preload: :front_image
      )
    )
  end

  @doc """
  Counts the number of products.
  """
  def count_products() do
    Repo.aggregate(Product, :count)
  end

  def count_products(query) when query in ["", nil] do
    count_products()
  end

  def count_products(query) do
    Repo.aggregate(from(p in Product, where: ilike(p.name, ^"%#{query}%")), :count)
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

  @doc """
  Gets all featured products.
  """
  def get_featured_products() do
    Repo.all(from p in Product, where: p.is_featured == true, preload: :front_image)
  end
end
