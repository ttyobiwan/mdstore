defmodule Mdstore.Payments.Stripe do
  @moduledoc """
  A module for handling Stripe payment operations including customer management
  and payment intent creation.

  This module provides a wrapper around the Stripe API for common payment
  operations used in the Mdstore application.
  """

  alias Stripe.{PaymentIntent, Customer}

  @doc """
  Retrieves a Stripe customer by their email address.

  ## Parameters
    * `email` - The email address to search for

  ## Returns
    * `{:ok, %Stripe.List{}}` - A Stripe list containing matching customers (limited to 1)
    * `{:error, %Stripe.Error{}}` - An error if the request fails

  ## Examples
      iex> Mdstore.Payments.Stripe.get_customer_by_email("user@example.com")
      {:ok, %Stripe.List{data: [%Stripe.Customer{email: "user@example.com"}]}}
  """
  def get_customer_by_email(email) do
    Customer.list(%{email: email, limit: 1})
  end

  @doc """
  Creates a new Stripe customer with the given email address.

  ## Parameters
    * `email` - The email address for the new customer

  ## Returns
    * `{:ok, %Stripe.Customer{}}` - The newly created customer
    * `{:error, %Stripe.Error{}}` - An error if the creation fails

  ## Examples
      iex> Mdstore.Payments.Stripe.create_customer("user@example.com")
      {:ok, %Stripe.Customer{email: "user@example.com"}}
  """
  def create_customer(email) do
    Customer.create(%{email: email})
  end

  @doc """
  Creates a payment intent for processing a payment.

  This function creates a Stripe PaymentIntent with the specified parameters.
  The payment intent is configured for future off-session usage.

  ## Parameters
    * `amount` - The payment amount in the smallest currency unit (e.g., cents for USD)
    * `currency` - The three-letter ISO currency code (e.g., "usd")
    * `customer_id` - The Stripe customer ID to associate with this payment
    * `metadata` - Optional metadata to attach to the payment intent (defaults to empty map)

  ## Returns
    * `{:ok, %Stripe.PaymentIntent{}}` - The created payment intent
    * `{:error, %Stripe.Error{}}` - An error if the creation fails

  ## Examples
      iex> Mdstore.Payments.Stripe.create_payment_intent(1000, "usd", "cus_123", %{order_id: "order_456"})
      {:ok, %Stripe.PaymentIntent{amount: 1000, currency: "usd"}}
  """
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
