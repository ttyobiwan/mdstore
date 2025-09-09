defmodule MdstoreWeb.CartLive.IndexTest do
  import Mdstore.ProductsFixtures
  import Phoenix.LiveViewTest
  import Mdstore.AccountsFixtures
  import Mdstore.CartsFixtures

  use MdstoreWeb.ConnCase, async: true

  describe "shopping cart page" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user}
    end

    test "shows empty cart when no cart exists", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/cart")

      assert html =~ "Your cart is empty"
    end

    test "shows empty cart when cart is empty", %{conn: conn, user: user} do
      cart_fixture(%{user_id: user.id})

      {:ok, _lv, html} = live(conn, ~p"/cart")

      assert html =~ "Your cart is empty"
    end

    test "shows cart products and summary", %{conn: conn, user: user} do
      cart = cart_fixture(%{user_id: user.id})
      product1 = product_fixture(%{price: 29.99, name: "Test Product 1"})
      product2 = product_fixture(%{price: 15.50, name: "Test Product 2"})
      cart_item_fixture(%{cart_id: cart.id, product_id: product1.id})
      cart_item_fixture(%{cart_id: cart.id, product_id: product2.id})

      {:ok, _lv, html} = live(conn, ~p"/cart")

      assert html =~ "Test Product 1"
      assert html =~ "Test Product 2"
      assert html =~ "$29.99"
      assert html =~ "$15.50"
      assert html =~ "Total (2 items)"
      assert html =~ "Order Summary"
      assert html =~ "Proceed to Checkout"
    end

    test "test removing product from the cart", %{conn: conn, user: user} do
      cart = cart_fixture(%{user_id: user.id})
      product = product_fixture()
      cart_item_fixture(%{cart_id: cart.id, product_id: product.id})

      {:ok, lv, _html} = live(conn, ~p"/cart")

      lv
      |> element("button[phx-click='remove_product'][phx-value-product_id='#{product.id}']")
      |> render_click()

      assert render(lv) =~ "Your cart is empty"
      assert render(lv) =~ "Item removed from the cart"
    end
  end
end
