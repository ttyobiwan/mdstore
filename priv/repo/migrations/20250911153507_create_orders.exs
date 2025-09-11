defmodule Mdstore.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :status, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
      add :checkout_id, references(:checkouts, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:user_id])
    create unique_index(:orders, [:checkout_id])
  end
end
