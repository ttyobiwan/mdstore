defmodule PhxstoreWeb.PageController do
  use PhxstoreWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
