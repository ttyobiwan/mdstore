defmodule Phxstore.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :description, :text
      add :quantity, :integer, default: 0
      add :price, :float, default: 0.0
      add :front_image_id, references(:images, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:products, [:front_image_id])

    create constraint(:products, :quantity_non_negative, check: "quantity >= 0")
    create constraint(:products, :price_non_negative, check: "price >= 0")
  end
end
