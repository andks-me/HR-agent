defmodule HrBrandAgent.Repo.Migrations.CreateLinkedinData do
  use Ecto.Migration

  def change do
    create table(:linkedin_data) do
      add :session_id, references(:research_sessions, on_delete: :delete_all), null: false
      add :data_type, :string, null: false  # company_info, job_post, review, post, employee_review
      add :title, :string
      add :content, :text
      add :url, :string
      add :author, :string
      add :posted_at, :utc_datetime
      add :metadata, :map, default: %{}
      add :sentiment_score, :float
      add :collected_at, :utc_datetime

      timestamps()
    end

    create index(:linkedin_data, [:session_id])
    create index(:linkedin_data, [:data_type])
    create index(:linkedin_data, [:sentiment_score])
  end
end
