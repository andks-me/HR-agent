defmodule HrBrandAgent.Research.WebData do
  use Ecto.Schema
  import Ecto.Changeset

  schema "web_data" do
    field :source, :string  # glassdoor, indeed, headhunter, etc.
    field :content, :string
    field :url, :string
    field :author, :string
    field :rating, :float
    field :job_title, :string
    field :review_date, :utc_datetime
    field :sentiment_score, :float
    field :metadata, :map, default: %{}
    field :collected_at, :utc_datetime

    belongs_to :session, HrBrandAgent.Research.Session

    timestamps()
  end

  @doc false
  def changeset(data, attrs) do
    data
    |> cast(attrs, [:source, :content, :url, :author, :rating, :job_title, :review_date, :sentiment_score, :metadata, :collected_at, :session_id])
    |> validate_required([:source, :session_id])
    |> validate_inclusion(:source, ["glassdoor", "indeed", "headhunter", "other"])
  end
end
