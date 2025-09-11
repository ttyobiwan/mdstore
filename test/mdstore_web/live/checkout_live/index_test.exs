defmodule MdstoreWeb.CheckoutLive.IndexTest do
  alias Mdstore.Carts
  import Mdstore.AccountsFixtures
  import Mdstore.CheckoutsFixtures
  import Mdstore.OrdersFixtures
  import Mdstore.CartsFixtures
  import Phoenix.LiveViewTest

  use MdstoreWeb.ConnCase, async: true

  describe "checkout page" do
    setup %{conn: conn} do
      user = user_fixture()

      cart = cart_fixture(%{user_id: user.id})
      cart_item_fixture(%{cart_id: cart.id})
      cart_item_fixture(%{cart_id: cart.id})
      cart_item_fixture(%{cart_id: cart.id})
      # Refresh the cart to get preloaded products
      cart = Carts.get_cart(user)

      conn = log_in_user(conn, user)
      %{conn: conn, user: user, cart: cart}
    end

    test "redirects to cart page if cart is empty", %{conn: conn, cart: cart} do
      {:ok, _cart} = Carts.close_cart(cart)
      {:error, redirect} = live(conn, ~p"/checkout")
      assert redirect == {:live_redirect, %{to: "/cart", flash: %{}}}
    end

    test "shows order summary", %{conn: conn, cart: cart} do
      {:ok, _lv, html} = live(conn, ~p"/checkout")

      assert html =~ "$3.00"

      for product <- cart.products do
        assert html =~ product.name
      end
    end

    test "submits payment form", %{conn: conn, user: user} do
      {:ok, lv, html} = live(conn, ~p"/checkout")

      assert html =~ "Setting up payment..."

      # Wait for form to load
      render_async(lv, 1000)

      checkout = last_checkout_fixture!(user)
      assert checkout.status == :started

      lv |> element("form") |> render_submit()

      assert_push_event(lv, "confirm_payment", %{client_secret: "supersecretclientsecret"})
      checkout = reload_checkout_fixture!(checkout)
      assert checkout.status == :submitted
      order = order_for_checkout_fixture!(checkout)
      assert order.status == :created
    end

    test "handles payment success", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/checkout")
      render_async(lv, 1000)
      lv |> element("form") |> render_submit()

      render_hook(lv, "payment_success", %{"payment_intent" => %{"id" => "pi_1"}})

      assert_redirected(lv, ~p"/products")
      checkout = last_checkout_fixture!(user)
      assert checkout.status == :successful
      # nil because its closed now
      assert Carts.get_cart(user) == nil
      order = order_for_checkout_fixture!(checkout)
      assert order.status == :paid
    end

    test "handles payment error", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/checkout")
      render_async(lv, 1000)
      lv |> element("form") |> render_submit()

      render_hook(lv, "payment_error", %{"error" => "Card declined"})

      assert render(lv) =~ "Something went wrong"
      checkout = last_checkout_fixture!(user)
      assert checkout.status == :failed
      order = order_for_checkout_fixture!(checkout)
      assert order.status == :created
    end
  end
end
