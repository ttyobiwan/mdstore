defmodule Mdstore.Repo.Migrations.AddProductIsFeatured do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :is_featured, :boolean, default: false
    end
  end
end
