defmodule PhxstoreWeb.AdminLive.Products.FormTest do
  use PhxstoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phxstore.AccountsFixtures
  import Phxstore.ProductsFixtures

  describe "new product form page" do
    test "displays empty form", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products/new")

      assert html =~ "Create product"
      assert html =~ "Name"
      assert html =~ "Description"
      assert html =~ "Quantity"
      assert html =~ "Price"
    end

    test "validates input", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products/new")

      html =
        lv
        |> form("#form", product: %{name: "", quantity: -1, price: -1})
        |> render_change()

      # name
      assert html =~ "can&#39;t be blank"
      # quantity/price
      assert html =~ "must be greater than or equal to 0"
      # front image
      assert html =~ "Front image is required"
    end

    test "creates new product", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products/new")

      png_data =
        <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8,
          2, 0, 0, 0, 144, 119, 83, 222, 0, 0, 0, 12, 73, 68, 65, 84, 8, 215, 99, 248, 15, 0, 1,
          1, 1, 0, 24, 221, 141, 219, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130>>

      assert render_upload(
               file_input(lv, "#form", :front_image, [
                 %{
                   last_modified: 1_594_171_879_000,
                   name: "test.png",
                   content: png_data,
                   size: byte_size(png_data),
                   type: "image/png"
                 }
               ]),
               "test.png"
             ) =~ "test.png"

      lv
      |> form("#form",
        product: %{
          name: "Test Product",
          description: "Test Description",
          quantity: 10,
          price: 99.99
        }
      )
      |> render_submit()

      flash = assert_redirected(lv, ~p"/admin/products")
      assert flash["info"] =~ "Product created successfully"
    end
  end

  describe "edit product form page" do
    test "renders filled form", %{conn: conn} do
      product = product_fixture()

      {:ok, lv, html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products/#{product.id}")

      assert html =~ "Edit product"
      assert has_element?(lv, "input[name='product[name]'][value='#{product.name}']")

      assert has_element?(
               lv,
               "input[name='product[description]'][value='#{product.description}']"
             )

      assert has_element?(lv, "input[name='product[quantity]'][value='#{product.quantity}']")
      assert has_element?(lv, "input[name='product[price]'][value='#{product.price}']")
      assert html =~ "Current image:"
      assert has_element?(lv, "img[src='#{product.front_image.name}']")
    end

    test "validates input", %{conn: conn} do
      product = product_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products/#{product.id}")

      html =
        lv
        |> form("#form", product: %{name: "", quantity: -1, price: -1})
        |> render_change()

      # name
      assert html =~ "can&#39;t be blank"
      # quantity/price
      assert html =~ "must be greater than or equal to 0"
    end

    test "updates existing product", %{conn: conn} do
      product = product_fixture()
      original_image_id = product.front_image.id

      {:ok, lv, _html} =
        conn
        |> log_in_user(admin_user_fixture())
        |> live(~p"/admin/products/#{product.id}")

      png_data =
        <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8,
          2, 0, 0, 0, 144, 119, 83, 222, 0, 0, 0, 12, 73, 68, 65, 84, 8, 215, 99, 248, 15, 0, 1,
          1, 1, 0, 24, 221, 141, 219, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130>>

      assert render_upload(
               file_input(lv, "#form", :front_image, [
                 %{
                   last_modified: 1_594_171_879_000,
                   name: "new_test.png",
                   content: png_data,
                   size: byte_size(png_data),
                   type: "image/png"
                 }
               ]),
               "new_test.png"
             ) =~ "new_test.png"

      lv
      |> form("#form", product: %{name: "new name"})
      |> render_submit()

      flash = assert_redirected(lv, ~p"/admin/products")
      assert flash["info"] =~ "Product updated successfully"

      updated_product = Phxstore.Products.get_product(product.id)
      assert updated_product.name == "new name"
      assert updated_product.front_image.id != original_image_id
      assert Phxstore.Repo.get(Phxstore.Files.Image, original_image_id) == nil
    end
  end
end
