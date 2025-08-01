defmodule PhxstoreWeb.AdminLive.Products.Index do
  use PhxstoreWeb, :live_view
  alias Phxstore.Products

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_title: "Admin | Products")
      |> stream(:products, Products.get_all_products())

    {:ok, socket}
  end

  def render(assigns) do
    # Requirements:
    # - paginated list of products
    # - each product with a button to edit and delete
    # - button to create a new product
    ~H"""
    <.link navigate={~p"/admin/products/new"}>Create product</.link>

    <div :for={{dom_id, product} <- @streams.products} id={dom_id}>
      <.link navigate={~p"/admin/products/#{product.id}"}>{product.name}</.link>
    </div>
    """
  end
end
