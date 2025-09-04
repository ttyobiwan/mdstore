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
      assert html =~ "Buy Now"
    end

    test "shows out of stock product", %{conn: conn} do
      product = product_fixture(%{quantity: 0})
      {:ok, _lv, html} = live(conn, ~p"/products/#{product.id}")

      assert html =~ "Out of Stock"
      assert html =~ "Notify"
      refute html =~ "Buy Now"
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

      lv |> element("button", "Buy Now") |> render_click()

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

      lv |> element("button", "Buy Now") |> render_click()

      assert render(lv) =~ "Payment Details"
    end

    test "handles purchase error for existing customer", %{conn: conn} do
      product = product_fixture(%{price: 0.0})
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy Now") |> render_click()

      assert render(lv) =~ "Something went wrong"
    end

    test "submits payment form", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy Now") |> render_click()
      lv |> element("form") |> render_submit()

      assert_push_event(lv, "confirm_payment", %{client_secret: "supersecretclientsecret"})
    end

    test "handles payment success", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy Now") |> render_click()
      lv |> element("form") |> render_submit()

      render_hook(lv, "payment_success", %{"payment_intent" => %{"id" => "pi_1"}})

      assert_redirected(lv, ~p"/products")
    end

    test "handles payment error", %{conn: conn, product: product} do
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy Now") |> render_click()
      lv |> element("form") |> render_submit()

      render_hook(lv, "payment_error", %{"error" => "Card declined"})

      assert render(lv) =~ "Something went wrong"
    end
  end

  describe "unauthenticated payment flow" do
    test "redirects to login when trying to purchase", %{conn: conn} do
      product = product_fixture()
      {:ok, lv, _html} = live(conn, ~p"/products/#{product.id}")

      lv |> element("button", "Buy Now") |> render_click()

      assert_redirected(lv, ~p"/users/log-in?next=/products/#{product.id}")
    end
  end
end
