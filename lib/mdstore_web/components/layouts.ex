defmodule MdstoreWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MdstoreWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <header class="navbar bg-base-200/50 border-b border-base-content/20 px-8 font-mono">
        <div class="navbar-start">
          <.link navigate="/" class="text-xl font-bold tracking-tight"># mdstore</.link>

          <div class="hidden lg:flex ml-8">
            <ul class="menu menu-horizontal px-1 space-x-2">
              <li><.link navigate="/products" class="btn btn-ghost rounded-none">Shop</.link></li>
              <li><.link navigate="/about" class="btn btn-ghost rounded-none">About</.link></li>
              <li><.link navigate="/faq" class="btn btn-ghost rounded-none">FAQ</.link></li>
            </ul>
          </div>
        </div>

        <div class="navbar-end">
          <!-- Mobile icons -->
          <.link navigate="/wishlist" class="btn btn-ghost btn-square lg:hidden">
            <.icon name="hero-heart" class="size-5" />
          </.link>
          <.link navigate="/cart" class="btn btn-ghost btn-square lg:hidden">
            <.icon name="hero-shopping-cart" class="size-5" />
          </.link>
          
    <!-- Mobile hamburger -->
          <div class="dropdown dropdown-end lg:hidden">
            <div tabindex="0" role="button" class="btn btn-ghost btn-square">
              <.icon name="hero-bars-3" class="size-5" />
            </div>
            <ul
              tabindex="0"
              class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 border border-base-content/20 rounded-none w-52"
            >
              <li><.link navigate="/products">Shop</.link></li>
              <li><.link navigate="/about">About</.link></li>
              <li><.link navigate="/faq">FAQ</.link></li>
              <%= if @current_scope do %>
                <li class="menu-title">{@current_scope.user.email}</li>
                <li><.link navigate="/users/settings">Account Settings</.link></li>
                <%= if @current_scope.user.is_admin do %>
                  <li><.link navigate="/admin">Admin</.link></li>
                <% end %>
                <li><.link href="/users/log-out" method="delete">Logout</.link></li>
              <% else %>
                <li><.link navigate="/users/log-in">Login</.link></li>
              <% end %>
              <li>
                <.simple_theme_toggle />
              </li>
            </ul>
          </div>
          
    <!-- Desktop icons -->
          <div class="hidden lg:flex items-center space-x-2">
            <.link navigate="/wishlist" class="btn btn-ghost btn-square">
              <.icon name="hero-heart" class="size-5" />
            </.link>
            <.link navigate="/cart" class="btn btn-ghost btn-square">
              <.icon name="hero-shopping-cart" class="size-5" />
            </.link>

            <%= if @current_scope do %>
              <div class="dropdown dropdown-end">
                <div tabindex="0" role="button" class="btn btn-ghost btn-square">
                  <.icon name="hero-user" class="size-5" />
                </div>
                <ul
                  tabindex="0"
                  class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 border border-base-content/20 rounded-none w-52"
                >
                  <li class="menu-title">{@current_scope.user.email}</li>
                  <li><.link navigate="/users/settings">Account Settings</.link></li>
                  <%= if @current_scope.user.is_admin do %>
                    <li><.link navigate="/admin">Admin</.link></li>
                  <% end %>
                  <li><.link href="/users/log-out" method="delete">Logout</.link></li>
                </ul>
              </div>
            <% else %>
              <.link navigate="/users/log-in" class="btn btn-ghost btn-square">
                <.icon name="hero-user" class="size-5" />
              </.link>
            <% end %>

            <.simple_theme_toggle />
          </div>
        </div>
      </header>

      <main class="font-mono flex-1 py-12">
        {render_slot(@inner_block)}
      </main>

      <footer class="border-t border-base-content/20 px-8 py-6 font-mono text-sm mt-auto">
        <div class="mx-auto max-w-5xl flex flex-col sm:flex-row justify-between items-center text-base-content/70">
          <div class="mb-2 sm:mb-0">
            © {DateTime.utc_now().year} mdstore. All rights reserved.
          </div>
          <div class="flex space-x-4">
            <.link navigate="/terms" class="hover:text-base-content">Terms</.link>
            <.link navigate="/privacy" class="hover:text-base-content">Privacy</.link>
            <.link navigate="/contact" class="hover:text-base-content">Contact</.link>
          </div>
        </div>
      </footer>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=lofi]_&]:left-1/3 [[data-theme=black]_&]:left-2/3 transition-[left]" />

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "lofi"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "black"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  @doc """
  Simple theme toggle between light and dark themes.
  """
  def simple_theme_toggle(assigns) do
    ~H"""
    <label class="swap swap-rotate">
      <input type="checkbox" class="theme-controller" value="black" />

      <.icon name="hero-sun" class="swap-off h-6 w-6" />
      <.icon name="hero-moon" class="swap-on h-6 w-6" />
    </label>
    """
  end
end
