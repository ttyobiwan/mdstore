defmodule Mdstore.Payments.Behavior do
  @moduledoc """
  Behavior module that defines the contract for payment-related operations.

  This behavior provides a common interface for payment providers to implement
  customer management and payment intent creation functionality.
  """

  @doc """
  Retrieves a customer by their email address.

  ## Parameters
    * `email` - The customer's email address

  ## Returns
    * `{:ok, customer}` - Successfully found the customer
    * `{:error, reason}` - Failed to find or retrieve the customer
  """
  @callback get_customer_by_email(email :: String.t()) :: {:ok, any()} | {:error, any()}

  @doc """
  Creates a new customer with the given email address.

  ## Parameters
    * `email` - The email address for the new customer

  ## Returns
    * `{:ok, customer}` - Successfully created the customer
    * `{:error, reason}` - Failed to create the customer
  """
  @callback create_customer(email :: String.t()) :: {:ok, any()} | {:error, any()}

  @doc """
  Creates a payment intent for the specified amount, currency, and customer.

  ## Parameters
    * `amount` - The payment amount in the smallest currency unit (e.g., cents)
    * `currency` - The currency code (e.g., "usd", "eur")
    * `customer_id` - The ID of the customer making the payment

  ## Returns
    * `{:ok, payment_intent}` - Successfully created the payment intent
    * `{:error, reason}` - Failed to create the payment intent
  """
  @callback create_payment_intent(
              amount :: integer(),
              currency :: String.t(),
              customer_id :: String.t()
            ) :: {:ok, any()} | {:error, any()}

  @doc """
  Creates a payment intent with additional metadata.

  ## Parameters
    * `amount` - The payment amount in the smallest currency unit (e.g., cents)
    * `currency` - The currency code (e.g., "usd", "eur")
    * `customer_id` - The ID of the customer making the payment
    * `metadata` - Additional metadata to attach to the payment intent

  ## Returns
    * `{:ok, payment_intent}` - Successfully created the payment intent
    * `{:error, reason}` - Failed to create the payment intent
  """
  @callback create_payment_intent(
              amount :: integer(),
              currency :: String.t(),
              customer_id :: String.t(),
              metadata :: map()
            ) :: {:ok, any()} | {:error, any()}
end
