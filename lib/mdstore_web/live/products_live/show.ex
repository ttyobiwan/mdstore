defmodule MdstoreWeb.ProductsLive.Show do
  use MdstoreWeb, :live_view
  import MdstoreWeb.MdComponents
  require Logger

  alias Mdstore.Products
  alias Stripe.PaymentIntent
  alias Mdstore.Products.Product

  @payment_processor Application.compile_env(:mdstore, :payment_processor)

  def mount(%{"id" => id}, _session, socket) do
    # 1. style the component
    # 2. clean up processor, imports and keys usage
    # 3. create intent async
    # 4. add tests

    case Products.get_product(id) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Product not found")
          |> push_navigate(to: ~p"/products")

        {:ok, socket}

      product ->
        socket =
          socket
          |> assign(:page_title, product.name)
          |> assign(:product, product)
          |> assign(:processing, false)
          |> assign(:intent, nil)
          |> assign(:card_error, nil)

        {:ok, socket}
    end
  end

  def handle_event("start-purchase", _params, socket) do
    with {:ok, customer} <- get_or_create_customer(socket.assigns.current_scope.user.email),
         {:ok, intent} <-
           @payment_processor.create_payment_intent(
             trunc(socket.assigns.product.price * 100),
             "eur",
             customer.id,
             %{
               product_id: socket.assigns.product.id
             }
           ) do
      Logger.info(
        "New payment intent created: #{socket.assigns.current_scope.user.email} #{intent.id}"
      )

      socket = assign(socket, :intent, intent)
      {:noreply, socket}
    else
      {:error, reason} ->
        Logger.error("Error when starting purchase: #{inspect(reason)}")

        socket =
          put_flash(
            socket,
            :error,
            "Something went wrong when setting up the payment. Please try again."
          )

        {:noreply, socket}
    end
  end

  def handle_event("card_valid", _params, socket) do
    {:noreply, assign(socket, :card_error, nil)}
  end

  def handle_event("card_error", %{"error" => error}, socket) do
    {:noreply, assign(socket, :card_error, error)}
  end

  def handle_event("submit_payment", _params, socket) do
    {:noreply,
     socket
     |> assign(:processing, true)
     |> push_event("confirm_payment", %{client_secret: socket.assigns.intent.client_secret})}
  end

  def handle_event("payment_success", %{"payment_intent" => _payment_intent}, socket) do
    socket =
      socket
      |> put_flash(:info, "Payment successful! Thank you for your purchase.")
      |> push_navigate(to: ~p"/products")

    {:noreply, socket}
  end

  def handle_event("payment_error", %{"error" => error}, socket) do
    socket =
      socket
      |> assign(:processing, false)
      |> assign(:card_error, error)

    {:noreply, socket}
  end

  defp get_or_create_customer(email) do
    case @payment_processor.get_customer_by_email(email) do
      {:ok, %{data: [customer]}} -> {:ok, customer}
      {:ok, %{data: []}} -> @payment_processor.create_customer(email)
      {:error, reason} -> {:error, reason}
    end
  end

  attr :product, Product, required: true
  attr :intent, PaymentIntent, required: false
  attr :processing, :boolean, required: true
  attr :card_error, :string, required: false

  def actions(assigns) do
    ~H"""
    <div class="border-t border-base-content/20 pt-6 space-y-4">
      <.md_button
        :if={@product.quantity > 0 and !@intent}
        disabled={@processing}
        phx-disable-with="Loading..."
        variant="primary"
        size="lg"
        phx-click="start-purchase"
      >
        <.icon name="hero-shopping-cart" class="w-5 h-5 mr-2" /> Buy Now
      </.md_button>

      <.md_button :if={@product.quantity == 0} variant="outline" size="lg">
        <.icon name="hero-bell" class="w-5 h-5 mr-2" /> Notify
      </.md_button>
    </div>

    <div :if={@intent} class="payment-form">
      <form phx-submit="submit_payment">
        <div class="form-group">
          <label for="card-element">Credit or debit card</label>
          <div
            id="card-element"
            phx-hook="StripeElements"
            data-stripe-key={Application.get_env(:stripity_stripe, :publishable_key)}
            phx-update="ignore"
          >
          </div>
          <div :if={@card_error} class="stripe-error-message">{@card_error}</div>
        </div>

        <.md_button disabled={@processing} phx-disable-with="Loading...">
          Pay Now
        </.md_button>
      </form>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-6 py-8">
      <!-- Breadcrumb Navigation -->
      <nav class="mb-8 flex items-center justify-between">
        <ol class="flex items-center space-x-2 text-sm text-base-content/60">
          <li>
            <.link navigate={~p"/products"} class="hover:text-base-content transition-colors">
              Products
            </.link>
          </li>
          <li class="flex items-center">
            <.icon name="hero-chevron-right" class="w-4 h-4 mx-2" />
            <span class="text-base-content font-medium">{@product.name}</span>
          </li>
        </ol>

        <.md_button navigate={~p"/products"} variant="ghost" size="md">
          <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back
        </.md_button>
      </nav>
      
    <!-- Product Details -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-12">
        <!-- Product Image -->
        <div class="space-y-4">
          <div class="aspect-square bg-base-200 border border-base-content/20 overflow-hidden">
            <img
              :if={@product.front_image}
              src={"/uploads/#{@product.front_image.name}"}
              alt={@product.name}
              class="w-full h-full object-cover"
            />
            <div
              :if={!@product.front_image}
              class="w-full h-full flex items-center justify-center text-base-content/40"
            >
              <.icon name="hero-photo" class="w-24 h-24" />
            </div>
          </div>
        </div>
        
    <!-- Product Information -->
        <div class="space-y-6">
          <div>
            <h1 class="text-3xl font-bold text-base-content mb-4">{@product.name}</h1>
            <div class="flex items-center gap-4 mb-4">
              <span class="text-3xl font-bold text-primary">
                ${:erlang.float_to_binary(@product.price, decimals: 2)}
              </span>
              <.md_badge :if={@product.quantity > 0} variant="success" style="outline" size="lg">
                <.icon name="hero-check-circle" class="w-4 h-4 mr-1" />
                In Stock ({@product.quantity} available)
              </.md_badge>
              <.md_badge :if={@product.quantity == 0} variant="error" style="outline" size="lg">
                <.icon name="hero-x-circle" class="w-4 h-4 mr-1" /> Out of Stock
              </.md_badge>
            </div>
          </div>

          <div :if={@product.description} class="border-t border-base-content/20 pt-6">
            <h2 class="text-lg font-semibold text-base-content mb-3">Description</h2>
            <div class="prose prose-base max-w-none text-base-content/80">
              <p class="whitespace-pre-wrap">{@product.description}</p>
            </div>
          </div>

          <.actions
            product={@product}
            intent={@intent}
            processing={@processing}
            card_error={@card_error}
          />
        </div>
      </div>
      
    <!-- Product Details Section -->
      <div class="mt-16 border-t border-base-content/20 pt-8">
        <h2 class="text-2xl font-bold text-base-content mb-6">Specification</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div class="space-y-4">
            <div class="border border-base-content/20 bg-base-50 p-4">
              <dt class="text-sm font-medium text-base-content/70">Product ID</dt>
              <dd class="text-base font-semibold text-base-content">#{@product.id}</dd>
            </div>
            <div class="border border-base-content/20 bg-base-50 p-4">
              <dt class="text-sm font-medium text-base-content/70">Price</dt>
              <dd class="text-base font-semibold text-base-content">
                ${:erlang.float_to_binary(@product.price, decimals: 2)}
              </dd>
            </div>
          </div>
          <div class="space-y-4">
            <div class="border border-base-content/20 bg-base-50 p-4">
              <dt class="text-sm font-medium text-base-content/70">Availability</dt>
              <dd class="text-base font-semibold text-base-content">
                {if @product.quantity > 0,
                  do: "#{@product.quantity} in stock",
                  else: "Out of stock"}
              </dd>
            </div>
            <div class="border border-base-content/20 bg-base-50 p-4">
              <dt class="text-sm font-medium text-base-content/70">Last Updated</dt>
              <dd class="text-base font-semibold text-base-content">
                {Calendar.strftime(@product.updated_at, "%B %d, %Y")}
              </dd>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
