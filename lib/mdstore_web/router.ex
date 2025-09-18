defmodule MdstoreWeb.Router do
  use MdstoreWeb, :router

  import Oban.Web.Router
  import MdstoreWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MdstoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  ## Public routes

  scope "/", MdstoreWeb do
    pipe_through :browser

    live_session :public,
      layout: {MdstoreWeb.Layouts, :default},
      on_mount: [{MdstoreWeb.UserAuth, :mount_current_scope}] do
      live "/", HomeLive.Index
      live "/products", ProductsLive.Index
      live "/products/:id", ProductsLive.Show
    end
  end

  ## Authenticated routes

  scope "/", MdstoreWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated_user,
      layout: {MdstoreWeb.Layouts, :default},
      on_mount: [{MdstoreWeb.UserAuth, :require_authenticated}] do
      live "/cart", CartLive.Index
      live "/checkout", CheckoutLive.Index
    end
  end

  ## Admin routes

  scope "/admin", MdstoreWeb do
    pipe_through [:browser, :require_admin_user]

    live_session :admin_user,
      layout: {MdstoreWeb.Layouts, :default},
      on_mount: [{MdstoreWeb.UserAuth, :mount_current_scope}] do
      live "/", AdminLive.Index, :index
      live "/products", AdminLive.Products.Index, :index
      live "/products/new", AdminLive.Products.Form, :new
      live "/products/:id", AdminLive.Products.Form, :edit
    end
  end

  ## Authentication routes (public)
  scope "/users", MdstoreWeb do
    pipe_through [:browser]

    live_session :auth_public,
      on_mount: [{MdstoreWeb.UserAuth, :mount_current_scope}] do
      live "/register", UserLive.Registration, :new
      live "/log-in", UserLive.Login, :new
      live "/log-in/:token", UserLive.Confirmation, :new
    end

    post "/log-in", UserSessionController, :create
    delete "/log-out", UserSessionController, :delete
  end

  ## User authenticated routes
  scope "/", MdstoreWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :auth_authenticated,
      on_mount: [{MdstoreWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  ## Enable LiveDashboard and Swoosh mailbox preview in development

  if Application.compile_env(:mdstore, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MdstoreWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Oban routes

  scope "/" do
    pipe_through :browser
    oban_dashboard("/oban", resolver: Mdstore.Resolver)
  end
end
