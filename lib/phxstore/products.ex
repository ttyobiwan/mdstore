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
end
