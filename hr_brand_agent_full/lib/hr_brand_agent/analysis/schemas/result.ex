defmodule HrBrandAgent.Analysis.Result do
  use Ecto.Schema
  import Ecto.Changeset

  schema "analysis_results" do
    field :analysis_type, :string  # sentiment, funnel, red_flags, competitors
    field :results, :map, default: %{}
    field :generated_at, :utc_datetime

    belongs_to :session, HrBrandAgent.Research.Session

    timestamps()
  end

  @doc false
  def changeset(result, attrs) do
    result
    |> cast(attrs, [:analysis_type, :results, :generated_at, :session_id])
    |> validate_required([:analysis_type, :session_id])
    |> validate_inclusion(:analysis_type, ["sentiment", "funnel", "red_flags", "competitors"])
  end
end
