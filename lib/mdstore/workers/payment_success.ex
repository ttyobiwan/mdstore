defmodule Mdstore.Workers.PaymentSuccess do
  alias Mdstore.Carts
  alias Mdstore.Checkouts
  alias Mdstore.Orders
  require Logger

  use Oban.Worker, queue: :payments

  @impl true
  def perform(%Oban.Job{args: %{"order_id" => order_id}}), do: process_payment_success(order_id)

  @doc """
  Processes a successful payment for the given order.

  Handles the post-payment success workflow by:
  1. Updating the checkout status to :successful
  2. Updating the order status to :paid
  3. Closing the associated cart

  ## Parameters

    * `order_id` - The ID of the order to process

  ## Returns

    * `:ok` - When all operations complete successfully
    * `{:error, :order_not_found}` - When the order doesn't exist
    * `{:error, reason}` - When any of the update operations fail

  ## Examples

      iex> process_payment_success("valid_order_id")
      :ok

      iex> process_payment_success("invalid_order_id")
      {:error, :order_not_found}

  """
  def process_payment_success(order_id) do
    Logger.info("Processing order #{order_id}")

    case Orders.get_order(order_id) do
      nil ->
        Logger.error("Order #{order_id} not found")
        {:error, :order_not_found}

      order ->
        # Transaction is not necessary here, as corruption of one doesn't break the others
        with {:ok, _checkout} <- Checkouts.update_status(order.checkout, :successful),
             {:ok, _order} <- Orders.update_order_status(order, :paid),
             {:ok, _cart} <- close_cart(order.checkout.cart) do
          Logger.info("Order #{order_id} successfully processed")
          :ok
        else
          {:error, reason} ->
            Logger.error("Error when processing order #{order_id}: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp close_cart(nil), do: {:ok, nil}
  defp close_cart(cart), do: Carts.close_cart(cart)
end
