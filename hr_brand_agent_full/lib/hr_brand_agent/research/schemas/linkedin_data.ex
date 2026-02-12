defmodule HrBrandAgent.Research.LinkedinData do
  use Ecto.Schema
  import Ecto.Changeset

  schema "linkedin_data" do
    field :data_type, :string  # company_info, job_post, review, post, employee_review
    field :title, :string
    field :content, :string
    field :url, :string
    field :author, :string
    field :posted_at, :utc_datetime
    field :metadata, :map, default: %{}
    field :sentiment_score, :float
    field :collected_at, :utc_datetime

    belongs_to :session, HrBrandAgent.Research.Session

    timestamps()
  end

  @doc false
  def changeset(data, attrs) do
    data
    |> cast(attrs, [:data_type, :title, :content, :url, :author, :posted_at, :metadata, :sentiment_score, :collected_at, :session_id])
    |> validate_required([:data_type, :session_id])
    |> validate_inclusion(:data_type, ["company_info", "job_post", "review", "post", "employee_review"])
  end
end
