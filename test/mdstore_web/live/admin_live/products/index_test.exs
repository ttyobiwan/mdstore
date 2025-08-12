defmodule MdstoreWeb.AdminLive.Products.IndexTest do
  use MdstoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mdstore.AccountsFixtures
  import Mdstore.ProductsFixtures

  describe "product list page" do
    test "displays empty table", %{conn: conn} do
      #
      {:ok, _lv, html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products")

      assert html =~ "Products"
      assert html =~ "New product"
      refute html =~ "<tbody>"
    end

    test "displays a table with products", %{conn: conn} do
      product1 = product_fixture()
      product2 = product_fixture()
      product3 = product_fixture()

      {:ok, lv, html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products")

      assert html =~ product1.name
      assert html =~ product2.name
      assert html =~ product3.name

      assert has_element?(lv, "a", "Edit")
      assert has_element?(lv, "button", "Delete")
      assert has_element?(lv, "button[disabled]", "Previous")
      assert has_element?(lv, "button[disabled]", "Next")
    end

    test "paginates products", %{conn: conn} do
      products = for _i <- 1..15, do: product_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products?per_page=5")

      html = render(lv)
      assert html =~ "Page 1 of 3"

      first_5_products = Enum.take(products, 5)

      for product <- first_5_products do
        assert html =~ product.name
      end

      remaining_10_products = Enum.drop(products, 5)

      for product <- remaining_10_products do
        refute html =~ product.name
      end

      lv
      |> element("button", "Next")
      |> render_click()

      html = render(lv)
      assert html =~ "Page 2 of 3"

      {:ok, lv, html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products?per_page=25")

      assert html =~ "Page 1 of 1"
      assert has_element?(lv, "button[disabled]", "Previous")
      assert has_element?(lv, "button[disabled]", "Next")
    end

    test "shows a delete product modal", %{conn: conn} do
      product1 = product_fixture(%{name: "Product 1"})
      product2 = product_fixture(%{name: "Product 2"})

      {:ok, lv, html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products")

      assert html =~ product1.name
      assert html =~ product2.name
      refute has_element?(lv, ".modal-open")

      lv
      |> element("#delete-product-#{product1.id}")
      |> render_click()

      assert has_element?(lv, ".modal-open")
      assert render(lv) =~ "Delete Product"
      assert render(lv) =~ product1.name

      lv
      |> element("#confirm-delete-product")
      |> render_click()

      refute has_element?(lv, ".modal-open")
      html = render(lv)
      refute html =~ product1.name
      assert html =~ product2.name
      assert html =~ "Product deleted successfully"
    end
  end
end
