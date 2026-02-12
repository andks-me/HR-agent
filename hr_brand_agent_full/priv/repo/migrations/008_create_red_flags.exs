defmodule HrBrandAgent.Repo.Migrations.CreateRedFlags do
  use Ecto.Migration

  def change do
    create table(:red_flags) do
      add :session_id, references(:research_sessions, on_delete: :delete_all), null: false
      add :flag_id, :integer, null: false  # 1-7
      add :flag_name, :string, null: false
      add :severity, :string, null: false  # low, medium, high
      add :frequency, :integer, default: 0
      add :evidence, {:array, :text}, default: []
      add :sources, {:array, :string}, default: []
      add :description, :text

      timestamps()
    end

    create index(:red_flags, [:session_id])
    create index(:red_flags, [:flag_id])
    create index(:red_flags, [:severity])
  end
end
