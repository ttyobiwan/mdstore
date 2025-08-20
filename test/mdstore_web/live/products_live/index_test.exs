defmodule MdstoreWeb.ProductsLive.IndexTest do
  use MdstoreWeb.ConnCase, async: true
  import Mdstore.ProductsFixtures
  import Phoenix.LiveViewTest

  describe "product list page" do
    test "shows an empty page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/products")
      assert html =~ "No products available"
    end

    test "shows a list of product", %{conn: conn} do
      product1 = product_fixture()
      product2 = product_fixture()
      product3 = product_fixture()

      {:ok, _lv, html} = live(conn, ~p"/products")

      assert html =~ product1.name
      assert html =~ product2.name
      assert html =~ product3.name
    end

    test "searches for products", %{conn: conn} do
      product1 = product_fixture(%{name: "x TERM x"})
      product2 = product_fixture(%{name: "term x"})
      product3 = product_fixture()

      {:ok, _lv, html} = live(conn, ~p"/products?q=term")

      assert html =~ product1.name
      assert html =~ product2.name
      refute html =~ product3.name
    end

    test "paginates the products", %{conn: conn} do
      product1 = product_fixture(%{name: "x TERM x"})
      product2 = product_fixture(%{name: "term x"})
      product3 = product_fixture()

      {:ok, _lv, html} = live(conn, ~p"/products?q=term&per_page=1")

      assert html =~ product1.name
      refute html =~ product2.name
      refute html =~ product3.name

      assert html =~ "Showing 1 of 2 products"
      assert html =~ "Page 1 of 2"
    end
  end
end
