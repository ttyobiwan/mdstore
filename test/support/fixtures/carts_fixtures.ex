defmodule Mdstore.CartsFixtures do
  alias Mdstore.ProductsFixtures
  alias Mdstore.AccountsFixtures
  alias Mdstore.Carts

  def valid_cart_attributes(attrs \\ %{}) do
    attrs
    |> Map.put_new_lazy(:user_id, fn -> AccountsFixtures.user_fixture().id end)
  end

  def valid_cart_item_attributes(attrs \\ %{}) do
    attrs
    |> Map.put_new_lazy(:cart_id, fn -> cart_fixture().id end)
    |> Map.put_new_lazy(:product_id, fn -> ProductsFixtures.product_fixture().id end)
    |> Enum.into(%{quantity: 1})
  end

  def cart_fixture(attrs \\ %{}) do
    {:ok, cart} =
      attrs
      |> valid_cart_attributes()
      |> Carts.create_cart()

    cart
  end

  def cart_item_fixture(attrs \\ %{}) do
    :ok =
      attrs
      |> valid_cart_item_attributes()
      |> then(fn attrs ->
        Carts.add_to_cart(%{id: attrs.cart_id}, %{id: attrs.product_id}, attrs.quantity)
      end)
  end
end
