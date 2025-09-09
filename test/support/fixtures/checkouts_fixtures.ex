defmodule Mdstore.CheckoutsFixtures do
  alias Mdstore.Checkouts.Checkout
  alias Mdstore.Repo
  import Ecto.Query

  def last_checkout_fixture!(user) do
    Repo.one!(from c in Checkout, where: c.user_id == ^user.id, limit: 1, order_by: c.inserted_at)
  end

  def last_checkout_fixture!(user, cart) do
    Repo.one!(
      from c in Checkout,
        where: c.user_id == ^user.id and c.cart_id == ^cart.id,
        limit: 1,
        order_by: c.inserted_at
    )
  end

  def reload_checkout_fixture!(checkout) do
    Repo.reload!(checkout)
  end
end
