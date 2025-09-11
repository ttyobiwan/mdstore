defmodule Mdstore.OrdersFixtures do
  alias Mdstore.Orders.Order
  alias Mdstore.Repo
  import Ecto.Query

  def order_for_checkout_fixture!(checkout) do
    Repo.one!(from o in Order, where: o.checkout_id == ^checkout.id)
  end
end
