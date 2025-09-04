defmodule Mdstore.Payments.Test do
  def get_customer_by_email("nonexisting@email.com") do
    {:ok, %{data: []}}
  end

  def get_customer_by_email("wrongemail") do
    {:error, "Invalid email address"}
  end

  def get_customer_by_email(email) do
    {:ok, %{data: [%{id: "cus_1", email: email}]}}
  end

  def create_payment_intent(_amount, _currency, _customer_id, _metadata \\ %{})

  def create_payment_intent(0, _currency, _customer_id, _metadata) do
    {:error, "Invalid amount"}
  end

  def create_payment_intent(_amount, _currency, _customer_id, _metadata) do
    {:ok, %{id: "pi_1", client_secret: "supersecretclientsecret"}}
  end

  def create_customer("wrongemail") do
    {:error, "Invalid email address"}
  end

  def create_customer(email) do
    {:ok, %{id: "cus_1", email: email}}
  end
end
