defmodule HrBrandAgent.Repo.Migrations.CreateAiQueries do
  use Ecto.Migration

  def change do
    create table(:ai_queries) do
      add :session_id, references(:research_sessions, on_delete: :delete_all), null: false
      add :query_type, :string, null: false  # reputation, hiring_process, red_flags, competitors
      add :query_text, :text
      add :response_text, :text
      add :model_used, :string
      add :tokens_used, :integer
      add :cost, :float
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:ai_queries, [:session_id])
    create index(:ai_queries, [:query_type])
  end
end
