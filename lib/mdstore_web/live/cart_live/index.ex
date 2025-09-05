defmodule MdstoreWeb.CartLive.Index do
  alias Mdstore.Images
  alias Mdstore.Carts
  import MdstoreWeb.MdComponents

  use MdstoreWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_title: "Cart")
      |> assign(:cart, Carts.get_cart(current_user(socket)))

    {:ok, socket}
  end

  def handle_event("remove_product", %{"product_id" => product_id}, socket) do
    Carts.remove_from_cart(socket.assigns.cart, %{id: product_id})

    socket =
      socket
      |> assign(:cart, Carts.get_cart(current_user(socket)))
      |> put_flash(:info, "Item removed from the cart")

    {:noreply, socket}
  end

  defp current_user(socket), do: socket.assigns.current_scope.user

  defp calculate_total(products) do
    products
    |> Enum.reduce(Decimal.new(0), fn product, acc ->
      Decimal.add(acc, Decimal.from_float(product.price))
    end)
    |> Decimal.to_string()
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-4">
      <div class="pb-8 mb-8">
        <h1 class="text-3xl font-bold text-base-content mb-4">Cart</h1>
        <p class="text-base-content/70 text-md max-w-2xl">
          Review your selected items and proceed to checkout when you're ready.
        </p>
      </div>

      <div :if={@cart && @cart.products != []}>
        <.md_table id="cart-items" rows={@cart.products}>
          <:col :let={product} label="Product">
            <div class="flex items-center gap-4">
              <.link href={"/products/#{product.id}"}>
                <img
                  :if={product.front_image}
                  src={Images.get_image_link(product.front_image)}
                  alt={product.name}
                  class="w-16 h-16 object-cover border border-base-content/20"
                />
              </.link>
              <div class="flex-1">
                <h3 class="font-semibold">{product.name}</h3>
                <p class="text-sm text-base-content/70 line-clamp-2">
                  {String.slice(product.description || "", 0, 50)}<span :if={
                    String.length(product.description || "") > 50
                  }>...</span>
                </p>
              </div>
            </div>
          </:col>
          <:col :let={product} label="Price">
            ${Decimal.from_float(product.price) |> Decimal.to_string()}
          </:col>
          <:action :let={product}>
            <.md_button
              variant="error"
              size="sm"
              phx-click="remove_product"
              phx-value-product_id={product.id}
            >
              Remove
            </.md_button>
          </:action>
        </.md_table>
        <div class="mt-6 p-4 bg-base-200 border border-base-content/20">
          <h3 class="text-lg font-semibold mb-2">Order Summary</h3>
          <div class="flex justify-between">
            <span>Total ({length(@cart.products)} items):</span>
            <span class="font-semibold">${calculate_total(@cart.products)}</span>
          </div>
        </div>
        <div class="flex justify-between items-center mt-6">
          <.md_button href={~p"/products"}>
            ← Continue Shopping
          </.md_button>
          <.md_button variant="primary" navigate="/checkout">
            Proceed to Checkout →
          </.md_button>
        </div>
      </div>

      <div :if={!@cart || @cart.products == []} class="text-center py-12">
        <h2 class="text-xl font-semibold mb-4">Your cart is empty</h2>
        <p class="text-base-content/70 mb-6">Add some products to get started</p>
        <.md_button variant="primary" href={~p"/products"}>
          Browse Products
        </.md_button>
      </div>
    </div>
    """
  end
end
