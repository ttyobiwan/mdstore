defmodule MdstoreWeb.ProductsLive.ShowTest do
  alias Mdstore.Images
  import Mdstore.ProductsFixtures
  import Mdstore.AccountsFixtures
  import Phoenix.LiveViewTest
  use MdstoreWeb.ConnCase, async: true

  describe "product show page" do
    test "shows product with image", %{conn: conn} do
      product = product_fixture()
      {:ok, _lv, html} = live(conn, ~p"/products/#{product.id}")

      assert html =~ product.name
      assert html =~ Images.get_image_link(product.front_image)
      assert html =~ "Buy now"
      assert html =~ "Add to cart"
    end

    test "shows out of stock product", %{conn: conn} do
      product = product_fixture(%{quantity: 0})
      {:ok, _lv, html} = live(conn, ~p"/products/#{product.id}")

      assert html =~ "Out of Stock"
      assert html =~ "Notify"
      refute html =~ "Buy now"
      refute html =~ "Add to cart"
    end
  end

  describe "add to cart flow" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      product = product_fixture()
      %{conn: conn, user: user, product: product}
    end

    test "adds product to cart successfully", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Add to cart") |> render_click()

      assert render(lv) =~ "Product added to cart successfully"
    end

    test "shows message when product is already in cart", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      # Add to cart first time
      lv |> element("button", "Add to cart") |> render_click()
      assert render(lv) =~ "Product added to cart successfully"

      # Try to add the same product again
      lv |> element("button", "Add to cart") |> render_click()
      assert render(lv) =~ "Product is already in the cart"
    end
  end

  describe "purchase flow" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      product = product_fixture()
      %{conn: conn, user: user, product: product}
    end

    test "starts purchase successfully", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy now") |> render_click()

      assert has_element?(lv, "#card-element")
      assert has_element?(lv, "form[phx-submit='submit_payment']")
      assert render(lv) =~ "Payment Details"
    end

    test "creates new customer when none exists", %{conn: conn} do
      user = user_fixture(%{email: "nonexisting@email.com"})
      product = product_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/products/#{product.id}")

      lv |> element("button", "Buy now") |> render_click()

      assert render(lv) =~ "Payment Details"
    end

    test "handles purchase error for existing customer", %{conn: conn} do
      product = product_fixture(%{price: 0.0})
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy now") |> render_click()

      assert render(lv) =~ "Something went wrong"
    end

    test "submits payment form", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy now") |> render_click()
      lv |> element("form") |> render_submit()

      assert_push_event(lv, "confirm_payment", %{client_secret: "supersecretclientsecret"})
    end

    test "handles payment success", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy now") |> render_click()
      lv |> element("form") |> render_submit()

      render_hook(lv, "payment_success", %{"payment_intent" => %{"id" => "pi_1"}})

      assert_redirected(lv, ~p"/products")
    end

    test "handles payment error", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy now") |> render_click()
      lv |> element("form") |> render_submit()

      render_hook(lv, "payment_error", %{"error" => "Card declined"})

      assert render(lv) =~ "Something went wrong"
    end

    test "hides add to cart and buy now buttons when payment intent is present", %{
      conn: conn,
      product: product
    } do
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      # Initially both buttons should be present
      assert has_element?(lv, "button", "Buy now")
      assert has_element?(lv, "button", "Add to cart")

      # Start purchase flow
      lv |> element("button", "Buy now") |> render_click()

      # After starting purchase, buttons should be hidden
      refute has_element?(lv, "button", "Buy now")
      refute has_element?(lv, "button", "Add to cart")
    end
  end

  describe "unauthenticated flows" do
    test "redirects to login when trying to purchase", %{conn: conn} do
      product = product_fixture()
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy now") |> render_click()

      assert_redirected(lv, ~p"/users/log-in?next=/products/#{product.id}")
    end

    test "redirects to login when trying to add to cart", %{conn: conn} do
      product = product_fixture()
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Add to cart") |> render_click()

      assert_redirected(lv, ~p"/users/log-in?next=/products/#{product.id}")
    end

    test "shows both buttons for unauthenticated users", %{conn: conn} do
      product = product_fixture()
      {:ok, _lv, html} = live(conn, ~p"/products/#{product.id}")

      assert html =~ "Buy now"
      assert html =~ "Add to cart"
    end
  end
end
