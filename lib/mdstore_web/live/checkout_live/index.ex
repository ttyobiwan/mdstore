defmodule MdstoreWeb.CheckoutLive.Index do
  import MdstoreWeb.MdComponents
  alias Mdstore.Orders
  alias Mdstore.Images
  alias Mdstore.Carts.Cart
  alias Mdstore.Accounts.User
  alias Phoenix.LiveView.AsyncResult
  alias Mdstore.Payments
  alias Mdstore.Checkouts
  alias Mdstore.Carts
  require Logger

  use MdstoreWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Checkout")
      |> assign(:loading, false)

    case Carts.get_cart(current_user(socket)) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/cart")}

      %{products: []} ->
        {:ok, push_navigate(socket, to: ~p"/cart")}

      cart ->
        user = current_user(socket)

        socket =
          socket
          |> assign(:cart, cart)
          |> assign(:checkout, AsyncResult.loading())
          |> assign(:customer, AsyncResult.loading())
          |> assign(:intent, AsyncResult.loading())
          |> assign(:order, nil)
          |> start_async(:setup_purchase, fn -> setup_purchase(user, cart) end)

        {:ok, socket}
    end
  end

  defp setup_purchase(%User{} = user, %Cart{} = cart) do
    total = calculate_total(cart.products)

    with {:ok, checkout} <-
           Checkouts.create_checkout(%{
             status: :started,
             total: total,
             user_id: user.id,
             cart_id: cart.id
           }),
         {:ok, customer} <- Payments.get_or_create_customer(user.email),
         {:ok, intent} <-
           Payments.create_payment_intent(
             trunc(total * 100),
             "eur",
             customer.id,
             %{
               cart_id: cart.id,
               checkout_id: checkout.id
             }
           ) do
      {:ok, {checkout, customer, intent}}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def handle_async(:setup_purchase, {:ok, {:ok, {checkout, customer, intent}}}, socket) do
    Logger.info("New payment intent created for #{current_user(socket).email}: #{intent.id}")

    socket =
      socket
      |> assign(:checkout, AsyncResult.ok(socket.assigns.checkout, checkout))
      |> assign(:customer, AsyncResult.ok(socket.assigns.customer, customer))
      |> assign(:intent, AsyncResult.ok(socket.assigns.intent, intent))

    {:noreply, socket}
  end

  def handle_async(:setup_purchase, {:ok, {:error, reason}}, socket) do
    Logger.error("Error when starting purchase: #{inspect(reason)}")

    socket =
      socket
      |> assign(:checkout, AsyncResult.failed(socket.assigns.checkout, {:error, reason}))
      |> assign(:customer, AsyncResult.failed(socket.assigns.customer, {:error, reason}))
      |> assign(:intent, AsyncResult.failed(socket.assigns.intent, {:error, reason}))
      |> put_flash(
        :error,
        "Something went wrong when setting up the payment. Please try again."
      )

    {:noreply, socket}
  end

  def handle_event("submit_payment", _params, socket) do
    Logger.info(
      "Payment submited by #{current_user(socket).email}: #{socket.assigns.intent.result.id}"
    )

    checkout = socket.assigns.checkout.result

    with {:ok, checkout} <- Checkouts.update_status(checkout, :submitted),
         {:ok, order} <-
           Orders.create_order(%{
             status: :created,
             user_id: current_user(socket).id,
             checkout_id: checkout.id
           }) do
      socket =
        socket
        |> assign(:loading, true)
        |> assign(:order, order)
        |> push_event("confirm_payment", %{
          client_secret: socket.assigns.intent.result.client_secret
        })

      {:noreply, socket}
    else
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
      "Payment successfull for #{current_user(socket).email}: #{socket.assigns.intent.result.id}"
    )

    with {:ok, _checkout} <- Checkouts.update_status(socket.assigns.checkout.result, :successful),
         {:ok, _order} <- Orders.update_order_status(socket.assigns.order, :paid),
         {:ok, _cart} <- Carts.close_cart(socket.assigns.cart) do
      :ok
    else
      {:error, reason} ->
        Logger.error(
          "Error handling payment success for #{current_user(socket).email}: #{inspect(reason)}"
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

    case Checkouts.update_status(socket.assigns.checkout.result, :failed) do
      {:ok, _checkout} ->
        :ok

      {:error, reason} ->
        Logger.error(
          "Error when updating checkout status for #{current_user(socket).email}: #{inspect(reason)}"
        )
    end

    socket =
      socket
      |> assign(:loading, true)
      |> put_flash(
        :error,
        "Something went wrong when processing the payment. Please try again."
      )

    {:noreply, socket}
  end

  defp stripe_public_key(), do: Application.get_env(:stripity_stripe, :publishable_key)

  defp current_user(socket), do: socket.assigns.current_scope.user

  defp calculate_total(products) do
    products
    |> Enum.reduce(Decimal.new(0), fn product, acc ->
      Decimal.add(acc, Decimal.from_float(product.price))
    end)
    |> Decimal.to_float()
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-6 py-8">
      <!-- Header -->
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-base-content mb-2">Checkout</h1>
        <p class="text-base-content/60">Complete your purchase</p>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Order Summary -->
        <div class="space-y-6">
          <div class="border border-base-content/20 bg-base-100 p-6">
            <h2 class="text-xl font-semibold text-base-content mb-4 flex items-center gap-2">
              <.icon name="hero-shopping-bag" class="w-5 h-5" /> Order Summary
            </h2>

            <div class="space-y-4">
              <div
                :for={product <- @cart.products}
                class="flex items-center gap-4 pb-4 border-b border-base-content/10 last:border-b-0"
              >
                <div class="w-16 h-16 bg-base-200 border border-base-content/20 overflow-hidden flex-shrink-0">
                  <img
                    :if={product.front_image}
                    src={Images.get_image_link(product.front_image)}
                    alt={product.name}
                    class="w-full h-full object-cover"
                  />
                  <div
                    :if={!product.front_image}
                    class="w-full h-full flex items-center justify-center text-base-content/40"
                  >
                    <.icon name="hero-photo" class="w-6 h-6" />
                  </div>
                </div>

                <div class="flex-1 min-w-0">
                  <h3 class="font-medium text-base-content truncate">{product.name}</h3>
                  <p class="text-sm text-base-content/60">Product #{product.id}</p>
                </div>

                <div class="text-right">
                  <p class="font-semibold text-base-content">
                    ${:erlang.float_to_binary(product.price, decimals: 2)}
                  </p>
                </div>
              </div>

              <div class="border-t border-base-content/20 pt-4">
                <div class="flex justify-between items-center text-lg font-bold text-base-content">
                  <span>Total</span>
                  <span class="text-primary">
                    ${:erlang.float_to_binary(calculate_total(@cart.products), decimals: 2)}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Payment Section -->
        <div class="space-y-6">
          <.async_result :let={_intent} assign={@intent}>
            <:loading>
              <div class="border border-base-content/20 bg-base-100 p-6">
                <div class="flex items-center justify-center py-8">
                  <div class="flex items-center gap-3">
                    <span class="loading loading-spinner loading-md"></span>
                    <span class="text-base-content/60">Setting up payment...</span>
                  </div>
                </div>
              </div>
            </:loading>

            <:failed :let={_failure}>
              <div class="border border-error/20 bg-error/10 p-6">
                <div class="flex items-center gap-3 text-error">
                  <.icon name="hero-exclamation-triangle" class="w-6 h-6" />
                  <div>
                    <h3 class="font-semibold">Payment Setup Failed</h3>
                    <p class="text-sm">Please try again or contact support.</p>
                  </div>
                </div>
              </div>
            </:failed>

            <div class="border border-base-content/20 bg-base-100 p-6">
              <h2 class="text-xl font-semibold text-base-content mb-4 flex items-center gap-2">
                <.icon name="hero-credit-card" class="w-5 h-5" /> Payment Details
              </h2>

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

                <div class="bg-base-200/50 p-4 border border-base-content/10">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-sm text-base-content/70">Subtotal</span>
                    <span class="text-sm font-medium">
                      ${:erlang.float_to_binary(calculate_total(@cart.products), decimals: 2)}
                    </span>
                  </div>
                  <div class="flex items-center justify-between font-semibold text-base-content">
                    <span>Total</span>
                    <span class="text-primary text-lg">
                      ${:erlang.float_to_binary(calculate_total(@cart.products), decimals: 2)}
                    </span>
                  </div>
                </div>

                <div class="space-y-4">
                  <.md_button
                    id="pay-button"
                    type="submit"
                    variant="primary"
                    size="lg"
                    class="w-full"
                    disabled={@loading}
                    phx-disable-with="Loading..."
                  >
                    <.icon name="hero-lock-closed" class="w-5 h-5 mr-2" /> Complete Payment
                  </.md_button>

                  <div class="text-center">
                    <p class="text-xs text-base-content/50">
                      Secure payment powered by Stripe
                    </p>
                  </div>
                </div>
              </form>
            </div>
          </.async_result>
        </div>
      </div>
    </div>
    """
  end
end
