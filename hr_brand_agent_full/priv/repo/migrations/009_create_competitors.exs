defmodule HrBrandAgent.Repo.Migrations.CreateCompetitors do
  use Ecto.Migration

  def change do
    create table(:competitors) do
      add :session_id, references(:research_sessions, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :website, :string
      add :industry, :string, default: "web3"
      add :comparison_data, :map, default: %{}
      add :reputation_score, :float
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:competitors, [:session_id])
    create index(:competitors, [:name])
  end
end
