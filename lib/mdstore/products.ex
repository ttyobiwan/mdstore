defmodule Mdstore.Products do
  @moduledoc """
  Context module for managing products.
  """

  alias Mdstore.Cache
  alias Mdstore.Images
  alias Mdstore.Repo
  alias Mdstore.Products.Product
  alias Ecto.Multi
  import Ecto.Query

  @doc """
  Creates a new product.

  ## Parameters

    * `attrs` - A map of attributes for the new product

  ## Returns

    * `{:ok, %Product{}}` - If the product was created successfully
    * `{:error, %Ecto.Changeset{}}` - If there was a validation error

  ## Examples

      iex> create_product(%{name: "Test Product", price: 100})
      {:ok, %Product{}}

      iex> create_product(%{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing product.

  ## Parameters

    * `product` - The `%Product{}` struct to update
    * `attrs` - A map of attributes to update

  ## Returns

    * `{:ok, %Product{}}` - If the product was updated successfully
    * `{:error, %Ecto.Changeset{}}` - If there was a validation error

  ## Examples

      iex> update_product(product, %{name: "Updated Name"})
      {:ok, %Product{}}

      iex> update_product(product, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a product by its ID.

  Returns the product with its front_image preloaded, or `nil` if not found.

  ## Parameters

    * `id` - The ID of the product to retrieve

  ## Returns

    * `%Product{}` - The product with front_image preloaded
    * `nil` - If no product with the given ID exists

  ## Examples

      iex> get_product(1)
      %Product{id: 1, front_image: %Image{}}

      iex> get_product(999)
      nil

  """
  def get_product(id) do
    Product
    |> Repo.get(id)
    |> Repo.preload(:front_image)
  end

  @doc """
  Gets all products with pagination.

  Returns a list of products with front_image preloaded, limited by pagination parameters.

  ## Parameters

    * `page` - The page number (1-indexed)
    * `per_page` - The number of products per page

  ## Returns

  A list of `%Product{}` structs with `:front_image` preloaded.

  ## Examples

      iex> get_all_products(1, 10)
      [%Product{}, ...]

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

  @doc """
  Gets all products with search query and pagination.

  Returns a list of products matching the search query, with front_image preloaded.
  If query is empty or nil, returns all products.

  ## Parameters

    * `query` - The search query string (searches product names)
    * `page` - The page number (1-indexed)
    * `per_page` - The number of products per page

  ## Returns

  A list of `%Product{}` structs with `:front_image` preloaded.

  ## Examples

      iex> get_all_products("shirt", 1, 10)
      [%Product{name: "Red Shirt"}, ...]

      iex> get_all_products("", 1, 10)
      [%Product{}, ...]

  """
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
  Counts the total number of products.

  ## Returns

  An integer representing the total number of products.

  ## Examples

      iex> count_products()
      42

  """
  def count_products() do
    Repo.aggregate(Product, :count)
  end

  @doc """
  Counts products matching a search query.

  Returns the total count of products whose names match the given query.
  If query is empty or nil, returns the total count of all products.

  ## Parameters

    * `query` - The search query string

  ## Returns

  An integer representing the count of matching products.

  ## Examples

      iex> count_products("shirt")
      5

      iex> count_products("")
      42

  """
  def count_products(query) when query in ["", nil] do
    count_products()
  end

  def count_products(query) do
    Repo.aggregate(from(p in Product, where: ilike(p.name, ^"%#{query}%")), :count)
  end

  @doc """
  Deletes a product and its associated images.

  This operation is performed within a database transaction to ensure
  both the product and its related images are deleted atomically.

  ## Parameters

    * `product` - The `%Product{}` struct to delete

  ## Returns

    * `{:ok, %{product: %Product{}, delete_image: any()}}` - If successful
    * `{:error, :product | :delete_image, any(), %{}}` - If the transaction fails

  ## Examples

      iex> delete_product(product)
      {:ok, %{product: %Product{}, delete_image: :ok}}

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
  Gets all featured products, prioritizing cached results.

  ## Returns

  A list of `%Product{}` structs with `:front_image` preloaded, or an empty
  list if no featured products exist.

  ## Examples

      iex> get_featured_products()
      [%Product{id: 1, name: "Featured Product", is_featured: true, front_image: %Image{}}, ...]

      iex> get_featured_products()
      []

  """
  def get_featured_products() do
    case Cache.get(:featured_products) do
      {:ok, products} when products not in [nil, []] ->
        products

      _ ->
        products =
          Repo.all(from p in Product, where: p.is_featured == true, preload: :front_image)

        Cache.set(:featured_products, products)
        products
    end
  end
end
