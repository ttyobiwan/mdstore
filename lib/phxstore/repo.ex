defmodule Phxstore.Repo do
  use Ecto.Repo,
    otp_app: :phxstore,
    adapter: Ecto.Adapters.Postgres
end
