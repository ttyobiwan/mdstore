defmodule MdstoreWeb.HomeLive.Index do
  use MdstoreWeb, :live_view
  import MdstoreWeb.MdComponents

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
          <.md_button navigate="/products" variant="primary" size="lg">
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
        <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          <.link
            navigate="/product/1"
            class="card bg-base-100 border border-base-content/20 rounded-none hover:shadow-lg transition-shadow"
          >
            <figure class="px-4 pt-4">
              <img
                src="https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&h=300&fit=crop"
                alt="Markdown Editor"
                class="w-full h-48 object-cover"
              />
            </figure>
            <div class="card-body">
              <h3 class="card-title text-base-content">Markdown Editor</h3>
              <p class="text-base-content/70 font-semibold">$29.99</p>
            </div>
          </.link>

          <.link
            navigate="/product/2"
            class="card bg-base-100 border border-base-content/20 rounded-none hover:shadow-lg transition-shadow"
          >
            <figure class="px-4 pt-4">
              <img
                src="https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=400&h=300&fit=crop"
                alt="Code Theme Pack"
                class="w-full h-48 object-cover"
              />
            </figure>
            <div class="card-body">
              <h3 class="card-title text-base-content">Code Theme Pack</h3>
              <p class="text-base-content/70 font-semibold">$19.99</p>
            </div>
          </.link>

          <.link
            navigate="/product/3"
            class="card bg-base-100 border border-base-content/20 rounded-none hover:shadow-lg transition-shadow"
          >
            <figure class="px-4 pt-4">
              <img
                src="https://images.unsplash.com/photo-1629904853893-c2c8981a1dc5?w=400&h=300&fit=crop"
                alt="CLI Tools"
                class="w-full h-48 object-cover"
              />
            </figure>
            <div class="card-body">
              <h3 class="card-title text-base-content">CLI Tools</h3>
              <p class="text-base-content/70 font-semibold">$39.99</p>
            </div>
          </.link>

          <.link
            navigate="/product/4"
            class="card bg-base-100 border border-base-content/20 rounded-none hover:shadow-lg transition-shadow"
          >
            <figure class="px-4 pt-4">
              <img
                src="https://images.unsplash.com/photo-1544256718-3bcf237f3974?w=400&h=300&fit=crop"
                alt="Documentation Kit"
                class="w-full h-48 object-cover"
              />
            </figure>
            <div class="card-body">
              <h3 class="card-title text-base-content">Documentation Kit</h3>
              <p class="text-base-content/70 font-semibold">$24.99</p>
            </div>
          </.link>
        </div>
      </div>
    </div>

    <!-- Call to Action -->
    <div class="bg-base-200/50 py-16 -mb-8">
      <div class="px-4 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-5xl text-center space-y-4">
          <h2 class="text-2xl font-bold text-base-content">
            ## Ready to get started?
          </h2>
          <p class="text-base-content/70">
            Join thousands of developers who trust mdstore for their tools and resources.
          </p>
          <.md_button navigate="/products" variant="primary" size="lg">
            Start Shopping
          </.md_button>
        </div>
      </div>
    </div>
    """
  end
end
