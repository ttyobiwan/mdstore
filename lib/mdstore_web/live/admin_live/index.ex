defmodule MdstoreWeb.AdminLive.Index do
  use MdstoreWeb, :live_view
  import MdstoreWeb.MdComponents

  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-8 flex flex-col items-center">
      <h1 class="text-3xl font-bold">Admin Dashboard</h1>

      <div class="flex gap-6">
        <.md_card>
          <.icon name="hero-users" class="h-12 w-12 text-primary mb-2" />
          <h3 class="text-2xl font-bold">1,247</h3>
          <p class="text-base-content/70">Total Users</p>
        </.md_card>

        <.md_card>
          <.icon name="hero-currency-dollar" class="h-12 w-12 text-success mb-2" />
          <h3 class="text-2xl font-bold">$23,890</h3>
          <p class="text-base-content/70">Total Revenue</p>
        </.md_card>

        <.md_card>
          <.icon name="hero-user-plus" class="h-12 w-12 text-info mb-2" />
          <h3 class="text-2xl font-bold">47</h3>
          <p class="text-base-content/70">New This Week</p>
        </.md_card>
      </div>

      <div class="flex flex-col items-center">
        <h2 class="text-xl font-semibold">Quick Actions</h2>
        <.md_card class="w-fit">
          <.link
            navigate={~p"/admin/products"}
            class="flex items-center gap-3 p-3 rounded-lg hover:bg-base-200 transition-colors"
          >
            <.icon name="hero-cube" class="h-6 w-6 text-primary" />
            <span class="text-lg">Manage Products</span>
          </.link>
        </.md_card>
      </div>
    </div>
    """
  end
end
