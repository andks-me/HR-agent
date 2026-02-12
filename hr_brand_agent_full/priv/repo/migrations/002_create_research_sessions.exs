defmodule HrBrandAgent.Repo.Migrations.CreateResearchSessions do
  use Ecto.Migration

  def change do
    create table(:research_sessions) do
      add :company_id, references(:companies, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :nilify_all)
      add :status, :string, default: "pending"
      add :data_sources, {:array, :string}, default: []
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:research_sessions, [:company_id])
    create index(:research_sessions, [:user_id])
    create index(:research_sessions, [:status])
  end
end
