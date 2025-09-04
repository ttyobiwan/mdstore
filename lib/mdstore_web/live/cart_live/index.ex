defmodule MdstoreWeb.CartLive.Index do
  use MdstoreWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <p>This is the cart.</p>
    """
  end
end
