defmodule HrBrandAgent.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name, :string, null: false
      add :website, :string
      add :industry, :string, default: "web3"
      add :linkedin_url, :string
      add :description, :text
      add :employee_count, :string
      add :founded, :string
      add :headquarters, :string
      add :metadata, :map, default: %{}

      timestamps()
    end

    create unique_index(:companies, [:name])
    create index(:companies, [:industry])
  end
end
