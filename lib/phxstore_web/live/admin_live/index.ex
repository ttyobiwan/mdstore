defmodule PhxstoreWeb.AdminLive.Index do
  use PhxstoreWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-8 flex flex-col items-center">
      <h1 class="text-3xl font-bold">Admin Dashboard</h1>

      <div class="flex gap-6">
        <div class="card bg-base-200 w-48 h-48">
          <div class="card-body items-center text-center">
            <.icon name="hero-users" class="h-12 w-12 text-primary mb-2" />
            <h3 class="card-title text-2xl">1,247</h3>
            <p class="text-base-content/70">Total Users</p>
          </div>
        </div>

        <div class="card bg-base-200 w-48 h-48">
          <div class="card-body items-center text-center">
            <.icon name="hero-currency-dollar" class="h-12 w-12 text-success mb-2" />
            <h3 class="card-title text-2xl">$23,890</h3>
            <p class="text-base-content/70">Total Revenue</p>
          </div>
        </div>

        <div class="card bg-base-200 w-48 h-48">
          <div class="card-body items-center text-center">
            <.icon name="hero-user-plus" class="h-12 w-12 text-info mb-2" />
            <h3 class="card-title text-2xl">47</h3>
            <p class="text-base-content/70">New This Week</p>
          </div>
        </div>
      </div>

      <div class="space-y-4 flex flex-col items-center">
        <h2 class="text-xl font-semibold">Quick Actions</h2>
        <div class="card bg-base-100 w-fit">
          <div class="card-body p-4">
            <.link
              navigate={~p"/admin/products"}
              class="flex items-center gap-3 p-3 rounded-lg hover:bg-base-200 transition-colors"
            >
              <.icon name="hero-cube" class="h-6 w-6 text-primary" />
              <span class="text-lg">Manage Products</span>
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
