defmodule Mdstore.Payments.Stripe do
  alias Stripe.{PaymentIntent, Customer}

  def get_customer_by_email(email) do
    Customer.list(%{email: email, limit: 1})
  end

  def create_customer(email) do
    Customer.create(%{email: email})
  end

  def create_payment_intent(amount, currency, customer_id, metadata \\ %{}) do
    PaymentIntent.create(%{
      amount: amount,
      currency: currency,
      customer: customer_id,
      metadata: metadata,
      setup_future_usage: "off_session"
    })
  end
end
