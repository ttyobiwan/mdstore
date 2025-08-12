defmodule Mdstore.Repo do
  use Ecto.Repo,
    otp_app: :mdstore,
    adapter: Ecto.Adapters.Postgres
end
