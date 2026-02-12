defmodule HrBrandAgent.Repo.Migrations.CreateAnalysisResults do
  use Ecto.Migration

  def change do
    create table(:analysis_results) do
      add :session_id, references(:research_sessions, on_delete: :delete_all), null: false
      add :analysis_type, :string, null: false  # sentiment, funnel, red_flags, competitors
      add :results, :map, default: %{}
      add :generated_at, :utc_datetime

      timestamps()
    end

    create index(:analysis_results, [:session_id])
    create index(:analysis_results, [:analysis_type])
    create unique_index(:analysis_results, [:session_id, :analysis_type])
  end
end
