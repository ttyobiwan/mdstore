defmodule MdstoreWeb.ProductsLive.Show do
  import MdstoreWeb.MdComponents
  alias Mdstore.Orders
  alias MdstoreWeb.UserAuth
  alias Mdstore.Checkouts
  alias Mdstore.Carts
  alias Mdstore.Payments
  alias Mdstore.Images
  alias Mdstore.Products
  alias Stripe.PaymentIntent
  alias Mdstore.Products.Product
  require Logger

  use MdstoreWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
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
          |> assign(:loading, false)
          |> assign(:intent, nil)
          |> assign(:order, nil)

        {:ok, socket}
    end
  end

  def handle_params(_params, uri, socket) do
    {:noreply, assign(socket, :uri, uri)}
  end

  def handle_event("add_to_cart", _params, socket)
      when socket.assigns.current_scope == nil or socket.assigns.current_scope.user == nil,
      do: redirect_to_login(socket)

  def handle_event("add_to_cart", _params, socket) do
    with {:ok, cart} <- Carts.get_or_create_cart(current_user(socket)),
         :ok <- Carts.add_to_cart(cart, socket.assigns.product) do
      socket = put_flash(socket, :info, "Product added to cart successfully")
      {:noreply, socket}
    else
      {:error, :product_already_in_cart} ->
        socket =
          put_flash(
            socket,
            :info,
            "Product is already in the cart"
          )

        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Error when adding product to cart: #{inspect(reason)}")

        socket =
          put_flash(
            socket,
            :error,
            "Something went wrong when adding product to the cart. Please try again."
          )

        {:noreply, socket}
    end
  end

  def handle_event("start_purchase", _params, socket)
      when socket.assigns.current_scope == nil or socket.assigns.current_scope.user == nil,
      do: redirect_to_login(socket)

  def handle_event("start_purchase", _params, socket) do
    with {:ok, checkout} <-
           Checkouts.create_checkout(%{
             status: :started,
             total: socket.assigns.product.price,
             user_id: current_user(socket).id,
             product_id: socket.assigns.product.id
           }),
         {:ok, customer} <- Payments.get_or_create_customer(current_user(socket).email),
         {:ok, intent} <-
           Payments.create_payment_intent(
             trunc(socket.assigns.product.price * 100),
             "eur",
             customer.id,
             %{
               product_id: socket.assigns.product.id,
               checkout_id: checkout.id
             }
           ) do
      Logger.info("New payment intent created for #{current_user(socket).email}: #{intent.id}")

      socket = socket |> assign(:checkout, checkout) |> assign(:intent, intent)
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

  def handle_event("submit_payment", _params, socket) do
    Logger.info("Payment submited by #{current_user(socket).email}: #{socket.assigns.intent.id}")

    case Orders.place_order(socket.assigns.checkout, current_user(socket), [
           %{product: socket.assigns.product, quantity: 1}
         ]) do
      {:ok, order} ->
        Logger.info(
          "Order successfully places for user #{current_user(socket).email}: #{order.id}"
        )

        socket =
          socket
          |> assign(:loading, true)
          |> assign(:order, order)
          |> push_event("confirm_payment", %{client_secret: socket.assigns.intent.client_secret})

        {:noreply, socket}

      {:error, reason} ->
        Logger.error(
          "Error when submitting payment for #{current_user(socket).email}: #{inspect(reason)}"
        )

        socket =
          put_flash(
            socket,
            :error,
            "Something went wrong when setting up the payment. Please try again."
          )

        {:noreply, socket}
    end
  end

  def handle_event("payment_success", %{"payment_intent" => _payment_intent}, socket) do
    Logger.info(
      "Payment successfull for #{current_user(socket).email}: #{socket.assigns.intent.id}"
    )

    # TODO: Move to context and retry with oban
    with {:ok, _checkout} <- Checkouts.update_status(socket.assigns.checkout, :successful),
         {:ok, _order} <- Orders.update_order_status(socket.assigns.order, :paid) do
      :ok
    else
      {:error, reason} ->
        Logger.error(
          "Error when handling payment success for #{current_user(socket).email}: #{inspect(reason)}"
        )
    end

    socket =
      socket
      |> put_flash(:info, "Payment successful! Thank you for your purchase.")
      |> push_navigate(to: ~p"/products")

    {:noreply, socket}
  end

  def handle_event("payment_error", %{"error" => error}, socket) do
    Logger.error("Error processing payment for #{current_user(socket).email}: #{inspect(error)}")

    case Checkouts.update_status(socket.assigns.checkout, :failed) do
      {:ok, _checkout} ->
        :ok

      {:error, reason} ->
        Logger.error(
          "Error when updating checkout status for #{current_user(socket).email}: #{inspect(reason)}"
        )
    end

    socket =
      socket
      |> assign(:loading, false)
      |> put_flash(
        :error,
        "Something went wrong when processing the payment. Please try again."
      )

    {:noreply, socket}
  end

  defp current_user(socket), do: socket.assigns.current_scope.user

  defp stripe_public_key(), do: Application.get_env(:stripity_stripe, :publishable_key)

  defp redirect_to_login(socket) do
    socket =
      socket
      |> put_flash(:info, "You need to first log in, before starting a purchase")
      |> UserAuth.push_navigate_to_login()

    {:noreply, socket}
  end

  attr :product, Product, required: true
  attr :intent, PaymentIntent, required: false
  attr :loading, :boolean, required: true

  def actions(assigns) do
    ~H"""
    <div class="border-t border-base-content/20 pt-6">
      <.md_button
        :if={@product.quantity > 0 and !@intent}
        disabled={@loading}
        phx-disable-with="Loading..."
        size="md"
        phx-click="start_purchase"
      >
        <.icon name="hero-currency-dollar" class="w-5 h-5 mr-2" /> Buy now
      </.md_button>

      <.md_button
        :if={@product.quantity > 0 and !@intent}
        disabled={@loading}
        phx-disable-with="Loading..."
        size="md"
        phx-click="add_to_cart"
      >
        <.icon name="hero-shopping-cart" class="w-5 h-5 mr-2" /> Add to cart
      </.md_button>

      <.md_button :if={@product.quantity == 0} variant="outline" size="lg">
        <.icon name="hero-bell" class="w-5 h-5 mr-2" /> Notify
      </.md_button>
    </div>

    <div
      :if={@intent}
      class="space-y-6 p-6 border border-base-content/20 bg-base-100/50 backdrop-blur-sm"
    >
      <div class="space-y-4">
        <h3 class="text-xl font-semibold text-base-content flex items-center gap-2">
          <.icon name="hero-credit-card" class="w-5 h-5" /> Payment Details
        </h3>

        <form phx-submit="submit_payment" class="space-y-6">
          <div class="space-y-3">
            <label for="card-element" class="block text-sm font-medium text-base-content/70">
              Card Information
            </label>
            <div
              id="card-error-display"
              class="hidden text-error text-sm font-medium flex items-center gap-2 bg-error/10 p-3 border border-error/20"
            >
              <.icon name="hero-exclamation-triangle" class="w-4 h-4 flex-shrink-0" />
              <span id="card-error-text"></span>
            </div>

            <div class="border border-base-content/20 bg-base-100 p-4 focus-within:border-primary focus-within:ring-2 focus-within:ring-primary/20 transition-all duration-200">
              <div
                id="card-element"
                phx-hook="StripeElements"
                data-stripe-key={stripe_public_key()}
                phx-update="ignore"
              >
              </div>
            </div>
          </div>

          <div class="flex items-center justify-between">
            <div class="text-sm text-base-content/60">
              Secure payment powered by Stripe
            </div>
            <.md_button
              id="pay-button"
              disabled={@loading}
              phx-disable-with="Loading..."
              variant="primary"
              size="md"
            >
              <.icon name="hero-lock-closed" class="w-4 h-4 mr-2" />
              {if @loading, do: "Loading...", else: "Pay Now"}
            </.md_button>
          </div>
        </form>
      </div>
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

        <.md_button phx-click={JS.dispatch("go-back")} variant="ghost" size="md">
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
              src={Images.get_image_link(@product.front_image)}
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

          <.actions product={@product} intent={@intent} loading={@loading} />
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
