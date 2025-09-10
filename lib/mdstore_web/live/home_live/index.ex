defmodule MdstoreWeb.HomeLive.Index do
  alias Mdstore.Images
  alias Phoenix.LiveView.AsyncResult
  alias Mdstore.Products
  import MdstoreWeb.MdComponents

  use MdstoreWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Store")
      |> assign(:featured_products, AsyncResult.loading())
      |> start_async(:get_featured_products, fn -> Products.get_featured_products() end)

    {:ok, socket}
  end

  def handle_async(:get_featured_products, {:ok, products}, socket) do
    {:noreply, assign(socket, :featured_products, AsyncResult.ok(products))}
  end

  def render(assigns) do
    ~H"""
    <!-- Hero Section -->
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-5xl text-center space-y-6">
        <h1 class="text-5xl font-bold text-base-content">
          # mdstore
        </h1>
        <p class="text-xl text-base-content/80 max-w-2xl mx-auto">
          Simple, markdown-inspired ecommerce. Clean design, powerful features.
        </p>
        <div class="flex gap-4 justify-center">
          <.md_button navigate={~p"/products"} variant="primary" size="lg">
            Browse Products
          </.md_button>
          <.md_button navigate="/about" variant="outline" size="lg">
            Learn More
          </.md_button>
        </div>
      </div>
    </div>

    <!-- Features Section -->
    <div class="bg-base-200/50 py-16 mt-16">
      <div class="px-4 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-5xl space-y-8">
          <div class="text-center space-y-4">
            <h2 class="text-3xl font-bold text-base-content">
              ## Features
            </h2>
            <p class="text-base-content/70 max-w-2xl mx-auto">
              Everything you need for a modern ecommerce experience, built with simplicity in mind.
            </p>
          </div>
          <div class="grid md:grid-cols-3 gap-6">
            <div class="card bg-base-100 border border-base-content/20 rounded-none mx-auto">
              <div class="card-body items-center text-center">
                <.icon name="hero-sparkles" class="w-8 h-8 mx-auto mb-2" />
                <h3 class="card-title">Simple Design</h3>
                <p class="text-base-content/70">
                  Clean, markdown-inspired interface that focuses on content over clutter.
                </p>
              </div>
            </div>

            <div class="card bg-base-100 border border-base-content/20 rounded-none mx-auto">
              <div class="card-body items-center text-center">
                <.icon name="hero-bolt" class="w-8 h-8 mx-auto mb-2" />
                <h3 class="card-title">Fast & Secure</h3>
                <p class="text-base-content/70">
                  Built with Phoenix LiveView for real-time updates and secure transactions.
                </p>
              </div>
            </div>

            <div class="card bg-base-100 border border-base-content/20 rounded-none mx-auto">
              <div class="card-body items-center text-center">
                <.icon name="hero-code-bracket" class="w-8 h-8 mx-auto mb-2" />
                <h3 class="card-title">Developer Friendly</h3>
                <p class="text-base-content/70">
                  Easy to customize and extend with markdown-like syntax and components.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Featured Products Section -->
    <div class="px-4 py-16 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-5xl space-y-8">
        <div class="text-center space-y-4">
          <h2 class="text-3xl font-bold text-base-content">
            ## Featured Products
          </h2>
          <p class="text-base-content/70 max-w-2xl mx-auto">
            Discover our most popular tools and resources for developers and creators.
          </p>
        </div>
        <div class="flex flex-wrap gap-6 justify-center">
          <.async_result :let={products} assign={@featured_products}>
            <:loading>
              <div class="flex justify-center basis-full">
                <div class="flex items-center gap-3">
                  <span class="loading loading-spinner loading-md"></span>
                  <span class="text-base-content/60">Loading featured products...</span>
                </div>
              </div>
            </:loading>

            <:failed :let={_failure}>
              <div class="basis-full">
                <div class="alert alert-error">
                  <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
                  <span>Failed to load featured products</span>
                </div>
              </div>
            </:failed>

            <.link
              :for={product <- products}
              navigate={~p"/products/#{product.id}"}
              class="card bg-base-100 border border-base-content/20 rounded-none hover:shadow-lg transition-shadow basis-full md:basis-[calc(50%-12px)] lg:basis-[calc(25%-18px)]"
            >
              <figure class="px-4 pt-4">
                <img
                  src={Images.get_image_link(product.front_image)}
                  alt={product.name}
                  class="w-full h-48 object-cover"
                />
              </figure>
              <div class="card-body">
                <h3 class="card-title text-base-content">{product.name}</h3>
                <p class="text-base-content/70 font-semibold">${product.price}</p>
              </div>
            </.link>
          </.async_result>
        </div>
      </div>
    </div>

    <!-- Call to Action -->
    <div class="bg-base-200/50 py-16 -mb-12">
      <div class="px-4 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-5xl text-center space-y-4">
          <h2 class="text-2xl font-bold text-base-content">
            ## Ready to get started?
          </h2>
          <p class="text-base-content/70">
            Join thousands of developers who trust mdstore for their tools and resources.
          </p>
          <.md_button navigate={~p"/products"} variant="primary" size="lg">
            Start Shopping
          </.md_button>
        </div>
      </div>
    </div>
    """
  end
end
