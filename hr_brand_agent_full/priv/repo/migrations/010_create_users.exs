defmodule HrBrandAgent.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false, collate: :nocase
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :role, :string, default: "user"
      add :name, :string
      add :avatar, :string
      add :settings, :map, default: %{}

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:role])
  end
end
