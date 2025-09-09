defmodule Mdstore.Repo.Migrations.CreateCheckouts do
  use Ecto.Migration

  def change do
    create table(:checkouts) do
      add :status, :string
      add :total, :float
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
      add :product_id, references(:products, type: :id, on_delete: :delete_all)
      add :cart_id, references(:carts, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:checkouts, [:user_id])
    create index(:checkouts, [:product_id], where: "product_id IS NOT NULL")
    create index(:checkouts, [:cart_id], where: "cart_id IS NOT NULL")
  end
end
