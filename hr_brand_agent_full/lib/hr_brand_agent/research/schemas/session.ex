defmodule HrBrandAgent.Research.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "research_sessions" do
    field :status, :string, default: "pending"
    field :data_sources, {:array, :string}, default: []
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :metadata, :map, default: %{}

    belongs_to :company, HrBrandAgent.Research.Company
    belongs_to :user, HrBrandAgent.Accounts.User
    has_many :linkedin_data, HrBrandAgent.Research.LinkedinData
    has_many :telegram_data, HrBrandAgent.Research.TelegramData
    has_many :web_data, HrBrandAgent.Research.WebData
    has_many :ai_queries, HrBrandAgent.Research.AIQuery
    has_many :analysis_results, HrBrandAgent.Analysis.Result
    has_many :red_flags, HrBrandAgent.Analysis.RedFlag
    has_many :competitors, HrBrandAgent.Analysis.Competitor

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:status, :data_sources, :started_at, :completed_at, :metadata, :company_id, :user_id])
    |> validate_required([:company_id])
    |> validate_inclusion(:status, ["pending", "in_progress", "completed", "failed"])
  end
end
