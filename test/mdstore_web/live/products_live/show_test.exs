defmodule MdstoreWeb.ProductsLive.ShowTest do
  use MdstoreWeb.ConnCase, async: true
  import Mdstore.ProductsFixtures
  import Phoenix.LiveViewTest

  describe "product show page" do
    test "shows a product", %{conn: conn} do
      product = product_fixture()

      {:ok, _lv, html} = live(conn, ~p"/products/#{product.id}")

      assert html =~ product.name
      assert html =~ "In Stock (#{product.quantity} available)"
    end

    test "redirects back to products with an error", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} = live(conn, ~p"/products/-1")

      assert path == ~p"/products"
      assert %{"error" => "Product not found"} = flash
    end
  end
end
