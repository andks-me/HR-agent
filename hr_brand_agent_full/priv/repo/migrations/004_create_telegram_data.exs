defmodule HrBrandAgent.Repo.Migrations.CreateTelegramData do
  use Ecto.Migration

  def change do
    create table(:telegram_data) do
      add :session_id, references(:research_sessions, on_delete: :delete_all), null: false
      add :chat_name, :string
      add :chat_id, :integer
      add :message_text, :text
      add :sender, :string
      add :sender_id, :integer
      add :message_date, :utc_datetime
      add :sentiment_score, :float
      add :is_about_company, :boolean, default: false
      add :is_about_competitor, :boolean, default: false
      add :keywords, {:array, :string}, default: []
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:telegram_data, [:session_id])
    create index(:telegram_data, [:is_about_company])
    create index(:telegram_data, [:is_about_competitor])
    create index(:telegram_data, [:sentiment_score])
  end
end
