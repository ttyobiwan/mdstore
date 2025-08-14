defmodule MdstoreWeb.AdminLive.Products.Index do
  use MdstoreWeb, :live_view
  import MdstoreWeb.MdComponents
  alias Mdstore.Products

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_title: "Admin · Products")
      |> assign(:delete_product, nil)
      |> assign(:total_count, Products.count_products())

    {:ok, socket}
  end

  def handle_params(params, _, socket) do
    query_params =
      Map.merge(%{"page" => "1", "per_page" => "10"}, Map.take(params, ~w(page per_page)))

    products =
      Products.get_all_products(page: query_params["page"], per_page: query_params["per_page"])

    per_page = String.to_integer(query_params["per_page"])
    current_page = String.to_integer(query_params["page"])
    total_pages = max(1, ceil(socket.assigns.total_count / per_page))

    socket =
      socket
      |> stream(:products, products, reset: true)
      |> assign(:query_params, query_params)
      |> assign(:total_pages, total_pages)
      |> assign(:current_page, current_page)

    {:noreply, socket}
  end

  def handle_event("show_delete_modal", %{"id" => id}, socket) do
    {:noreply, assign(socket, :delete_product, Products.get_product(id))}
  end

  def handle_event("hide_delete_modal", _, socket) do
    {:noreply, assign(socket, :delete_product, nil)}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    product = Products.get_product(id)

    case Products.delete_product(product) do
      {:ok, _} ->
        {:noreply,
         socket
         |> stream_delete(:products, product)
         |> assign(:delete_product, nil)
         |> assign(:total_count, socket.assigns.total_count - 1)
         |> put_flash(:info, "Product deleted successfully")}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:delete_product, nil)
         |> put_flash(:error, "Failed to delete product")}
    end
  end

  def handle_event("change_page", %{"page" => page}, socket) do
    updated_params = Map.put(socket.assigns.query_params, "page", page)
    {:noreply, push_patch(socket, to: ~p"/admin/products?#{updated_params}")}
  end

  def handle_event("change_per_page", %{"per_page" => per_page}, socket) do
    updated_params =
      socket.assigns.query_params
      |> Map.put("per_page", per_page)
      # Revert back to the first page
      |> Map.put("page", "1")

    {:noreply, push_patch(socket, to: ~p"/admin/products?#{updated_params}")}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="border-b border-base-300 pb-6 mb-8">
        <.header>
          Products
        </.header>
        <p class="text-base-content/80 mt-2 max-w-2xl">
          Manage your product catalog. Add, edit, or remove products from your store inventory.
        </p>
      </div>

      <div class="flex justify-between items-center mb-6">
        <div class="flex items-center gap-4">
          <form phx-change="change_per_page" class="flex items-center gap-2">
            <.md_input
              type="select"
              name="per_page"
              size="xs"
              value={@query_params["per_page"]}
              options={[{"5", "5"}, {"10", "10"}, {"25", "25"}, {"50", "50"}]}
            />
            <span class="text-sm text-base-content/60">products per page</span>
          </form>
        </div>

        <.md_button navigate={~p"/admin/products/new"}>
          <.icon name="hero-plus" class="w-4 h-4 mr-2" /> New product
        </.md_button>
      </div>

      <div class="bg-base-100 border border-base-300 rounded-lg overflow-hidden shadow-sm">
        <.md_table
          id="products"
          class="table-zebra"
          rows={@streams.products}
          row_click={fn {_id, product} -> JS.navigate(~p"/admin/products/#{product.id}") end}
        >
          <:col :let={{_id, product}} label="ID">
            <span class="text-sm text-base-content/70">#{product.id}</span>
          </:col>
          <:col :let={{_id, product}} label="Name">
            <span class="font-medium text-base-content">{product.name}</span>
          </:col>
          <:action :let={{_id, product}}>
            <.md_button navigate={~p"/admin/products/#{product}"} size="xs">
              Edit
            </.md_button>
          </:action>
          <:action :let={{_id, product}}>
            <.md_button
              id={"delete-product-#{product.id}"}
              phx-click={JS.push("show_delete_modal", value: %{id: product.id})}
              size="xs"
            >
              Delete
            </.md_button>
          </:action>
        </.md_table>
      </div>

      <div class="flex justify-between items-center mt-8">
        <p class="text-sm text-base-content/60">
          Showing page {@current_page} of {@total_pages}
        </p>
        <div class="join">
          <.md_button
            class="join-item btn btn-sm btn-outline"
            phx-click="change_page"
            phx-value-page={@current_page - 1}
            disabled={@current_page <= 1}
          >
            <.icon name="hero-chevron-left" class="w-4 h-4" /> Previous
          </.md_button>
          <.md_button
            class="join-item btn btn-sm btn-outline"
            phx-click="change_page"
            phx-value-page={@current_page + 1}
            disabled={@current_page >= @total_pages}
          >
            Next <.icon name="hero-chevron-right" class="w-4 h-4" />
          </.md_button>
        </div>
      </div>
    </div>

    <.md_modal
      id="delete-product-modal"
      show={@delete_product != nil}
      on_cancel={JS.push("hide_delete_modal")}
    >
      <h3 class="font-bold text-lg mb-4 text-base-content">Delete Product</h3>
      <div class="flex items-center gap-3 mb-6">
        <.icon name="hero-exclamation-triangle" class="w-8 h-8 text-error flex-shrink-0" />
        <p class="text-base-content">
          Are you sure you want to delete "<span class="font-semibold">{@delete_product.name}</span>"?
          This action cannot be undone.
        </p>
      </div>
      <div class="modal-action">
        <.md_button phx-click="hide_delete_modal" variant="outline">
          Cancel
        </.md_button>
        <.md_button
          id="confirm-delete-product"
          phx-click={JS.push("confirm_delete", value: %{id: @delete_product.id})}
          variant="error"
        >
          Delete
        </.md_button>
      </div>
    </.md_modal>
    """
  end
end
