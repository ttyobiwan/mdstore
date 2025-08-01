defmodule PhxstoreWeb.AdminLive.Index do
  use PhxstoreWeb, :live_view

  def render(assigns) do
    # Requirements:
    # - links to the admin panels (products, images, users, etc.)
    # - most important stats (new signups, all users, gmv, etc.)
    ~H"""
    <.link navigate={~p"/admin/products"}>Products</.link>
    """
  end
end
