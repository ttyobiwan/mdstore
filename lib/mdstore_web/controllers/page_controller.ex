defmodule MdstoreWeb.PageController do
  use MdstoreWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
