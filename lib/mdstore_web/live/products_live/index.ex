defmodule MdstoreWeb.ProductsLive.Index do
  use MdstoreWeb, :live_view
  import MdstoreWeb.MdComponents
  alias Mdstore.Products

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Products")}
  end

  def handle_params(params, _uri, socket) do
    query_params =
      %{"page" => "1", "per_page" => "10", "q" => ""}
      |> Map.merge(Map.take(params, ~w(page per_page q)))
      |> Map.reject(fn {_k, v} -> v in [nil, ""] end)

    query = query_params["q"]
    page = String.to_integer(query_params["page"])
    per_page = String.to_integer(query_params["per_page"])

    # Try to avoid excessive counting
    #
    total_count =
      cond do
        !socket.assigns[:total_count] -> Products.count_products(query)
        socket.assigns.query_params["q"] != query_params["q"] -> Products.count_products(query)
        true -> socket.assigns.total_count
      end

    total_pages = max(1, ceil(total_count / per_page))

    products =
      Products.get_all_products(
        query,
        page,
        per_page
      )

    socket =
      socket
      |> stream(:products, products, reset: true)
      |> assign(:products_count, length(products))
      |> assign(:query_params, query_params)
      |> assign(:total_pages, total_pages)
      |> assign(:total_count, total_count)

    {:noreply, socket}
  end

  def handle_event("change_page", %{"page" => page}, socket) do
    new_params = Map.put(socket.assigns.query_params, "page", page)
    {:noreply, push_patch(socket, to: ~p"/products?#{new_params}")}
  end

  def handle_event("change_per_page", %{"per_page" => per_page}, socket) do
    new_params =
      socket.assigns.query_params
      |> Map.put("page", 1)
      |> Map.put("per_page", per_page)

    {:noreply, push_patch(socket, to: ~p"/products?#{new_params}")}
  end

  def handle_event("search", %{"q" => ""}, socket) do
    new_params =
      socket.assigns.query_params
      |> Map.put("page", 1)
      |> Map.delete("q")

    {:noreply, push_patch(socket, to: ~p"/products?#{new_params}")}
  end

  def handle_event("search", %{"q" => _q} = params, socket) do
    params = Map.put(params, "page", 1)
    new_params = Map.merge(socket.assigns.query_params, params)
    new_params = Map.take(new_params, ~w(page per_page q))
    {:noreply, push_patch(socket, to: ~p"/products?#{new_params}")}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-6 py-8">
      <!-- Header Section -->
      <div class="border-b border-base-content/20 pb-8 mb-8">
        <h1 class="text-4xl font-bold text-base-content mb-4">Products</h1>
        <p class="text-base-content/70 text-lg max-w-2xl">
          Discover our curated collection of products. Find exactly what you're looking for with our simple search and browse experience.
        </p>
      </div>
      
    <!-- Search and Filters Section -->
      <div class="mb-8 space-y-4">
        <div class="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
          <!-- Search Input -->
          <div class="flex-1 max-w-md">
            <form phx-change="search">
              <.md_input
                name="q"
                value={@query_params["q"]}
                placeholder="Search products..."
                autocomplete="off"
                phx-debounce="250"
                size="lg"
              />
            </form>
          </div>
          
    <!-- Per Page Selector -->
          <div class="flex items-center gap-3">
            <span class="text-sm text-base-content/60 whitespace-nowrap">Show</span>
            <form phx-change="change_per_page">
              <.md_input
                type="select"
                name="per_page"
                size="sm"
                value={@query_params["per_page"]}
                options={[{"5", "5"}, {"10", "10"}, {"25", "25"}, {"50", "50"}]}
              />
            </form>
            <span class="text-sm text-base-content/60 whitespace-nowrap">per page</span>
          </div>
        </div>
        
    <!-- Results Info -->
        <div class="text-sm text-base-content/60">
          Showing {@products_count} of {@total_count} products
        </div>
      </div>
      
    <!-- Products Grid -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 mb-8">
        <div :for={{dom_id, product} <- @streams.products} id={dom_id}>
          <.link navigate={~p"/products/#{product.id}"} class="group block">
            <div class="border border-base-content/20 bg-base-100 hover:border-base-content/40 transition-all duration-200 h-full flex flex-col">
              <!-- Product Image -->
              <div class="aspect-square bg-base-200 relative overflow-hidden">
                <img
                  :if={product.front_image}
                  src={"/uploads/#{product.front_image.name}"}
                  alt={product.name}
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
                />
                <div
                  :if={!product.front_image}
                  class="w-full h-full flex items-center justify-center text-base-content/40"
                >
                  <.icon name="hero-photo" class="w-16 h-16" />
                </div>
              </div>
              
    <!-- Product Info -->
              <div class="p-4 flex-1 flex flex-col">
                <h3 class="font-semibold text-base-content mb-2 group-hover:text-primary transition-colors line-clamp-2">
                  {product.name}
                </h3>

                <p
                  :if={product.description}
                  class="text-sm text-base-content/70 mb-3 flex-1 line-clamp-3"
                >
                  {product.description}
                </p>

                <div class="flex items-center justify-between mt-auto pt-2">
                  <span class="text-lg font-bold text-primary">
                    ${:erlang.float_to_binary(product.price, decimals: 2)}
                  </span>

                  <.md_badge :if={product.quantity > 0} variant="success" size="xs">
                    In Stock
                  </.md_badge>

                  <.md_badge :if={product.quantity == 0} variant="error" size="xs">
                    Out of Stock
                  </.md_badge>
                </div>
              </div>
            </div>
          </.link>
        </div>
      </div>
      
    <!-- Empty State -->
      <div :if={@products_count == 0} class="text-center py-16">
        <.icon name="hero-magnifying-glass" class="w-16 h-16 text-base-content/40 mx-auto mb-4" />
        <h3 class="text-xl font-semibold text-base-content mb-2">
          {if @query_params["q"] && @query_params["q"] != "",
            do: "No products found",
            else: "No products available"}
        </h3>
        <p class="text-base-content/60 mb-4">
          {if @query_params["q"] && @query_params["q"] != "",
            do: "Try adjusting your search terms or browse all products.",
            else: "Check back later for new products."}
        </p>
        <.md_button
          :if={@query_params["q"] && @query_params["q"] != ""}
          phx-click="search"
          phx-value-q=""
          size="sm"
        >
          View all products
        </.md_button>
      </div>
      
    <!-- Pagination -->
      <div :if={@total_pages > 1} class="flex justify-center mt-8">
        <div class="join">
          <.md_button
            phx-click="change_page"
            phx-value-page={String.to_integer(@query_params["page"]) - 1}
            disabled={String.to_integer(@query_params["page"]) <= 1}
          >
            <.icon name="hero-chevron-left" class="w-4 h-4" /> Previous
          </.md_button>
          <.md_button
            phx-click="change_page"
            phx-value-page={String.to_integer(@query_params["page"]) + 1}
            disabled={String.to_integer(@query_params["page"]) >= @total_pages}
          >
            Next <.icon name="hero-chevron-right" class="w-4 h-4" />
          </.md_button>
        </div>
      </div>
      
    <!-- Pagination Info -->
      <div :if={@total_pages > 1} class="text-center text-sm text-base-content/60 mt-4">
        Page {String.to_integer(@query_params["page"])} of {@total_pages}
      </div>
    </div>
    """
  end
end
