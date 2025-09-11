defmodule Mdstore.Payments do
  @moduledoc """
  Payments context module that provides a unified interface for payment operations.

  This module delegates payment-related functionality to a configurable payment processor,
  allowing the application to work with different payment providers through a common API.
  The actual payment processor implementation is configured via the `:payment_processor`
  application environment variable.
  """

  @payment_processor Application.compile_env(:mdstore, :payment_processor)

  @doc """
  Retrieves an existing customer by email, or creates a new one if not found.

  ## Parameters
    * `email` - The email address of the customer

  ## Returns
  Returns `{:ok, customer}` if the customer exists or was successfully created,
  or `{:error, reason}` if an error occurred.
  """
  def get_or_create_customer(email) do
    case get_customer_by_email(email) do
      {:ok, %{data: [customer]}} -> {:ok, customer}
      {:ok, %{data: []}} -> create_customer(email)
      {:error, reason} -> {:error, reason}
    end
  end

  defdelegate get_customer_by_email(email), to: @payment_processor

  defdelegate create_customer(email), to: @payment_processor

  defdelegate create_payment_intent(amount, currency, customer_id, metadata \\ %{}),
    to: @payment_processor
end
