defmodule HrBrandAgent.Research.AIQuery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ai_queries" do
    field :query_type, :string  # reputation, hiring_process, red_flags, competitors
    field :query_text, :string
    field :response_text, :string
    field :model_used, :string
    field :tokens_used, :integer
    field :cost, :float
    field :metadata, :map, default: %{}

    belongs_to :session, HrBrandAgent.Research.Session

    timestamps()
  end

  @doc false
  def changeset(query, attrs) do
    query
    |> cast(attrs, [:query_type, :query_text, :response_text, :model_used, :tokens_used, :cost, :metadata, :session_id])
    |> validate_required([:query_type, :session_id])
    |> validate_inclusion(:query_type, ["reputation", "hiring_process", "red_flags", "competitors"])
  end
end
