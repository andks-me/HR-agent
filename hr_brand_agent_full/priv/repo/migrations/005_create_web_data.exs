defmodule HrBrandAgent.Repo.Migrations.CreateWebData do
  use Ecto.Migration

  def change do
    create table(:web_data) do
      add :session_id, references(:research_sessions, on_delete: :delete_all), null: false
      add :source, :string, null: false  # glassdoor, indeed, headhunter, etc.
      add :content, :text
      add :url, :string
      add :author, :string
      add :rating, :float
      add :job_title, :string
      add :review_date, :utc_datetime
      add :sentiment_score, :float
      add :metadata, :map, default: %{}
      add :collected_at, :utc_datetime

      timestamps()
    end

    create index(:web_data, [:session_id])
    create index(:web_data, [:source])
    create index(:web_data, [:rating])
    create index(:web_data, [:sentiment_score])
  end
end
