defmodule Mdstore.Resolver do
  @behaviour Oban.Web.Resolver

  alias Mdstore.Accounts.User

  @impl true
  def resolve_user(conn) do
    conn.assigns.current_scope.user
  end

  @impl true
  def resolve_access(%User{} = user) do
    case user do
      %{is_admin: true} -> :all
      _ -> {:forbidden, "/users/log-in"}
    end
  end
end
