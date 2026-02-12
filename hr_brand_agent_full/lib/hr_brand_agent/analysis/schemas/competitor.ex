defmodule HrBrandAgent.Analysis.Competitor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "competitors" do
    field :name, :string
    field :website, :string
    field :industry, :string, default: "web3"
    field :comparison_data, :map, default: %{}
    field :reputation_score, :float
    field :metadata, :map, default: %{}

    belongs_to :session, HrBrandAgent.Research.Session

    timestamps()
  end

  @doc false
  def changeset(competitor, attrs) do
    competitor
    |> cast(attrs, [:name, :website, :industry, :comparison_data, :reputation_score, :metadata, :session_id])
    |> validate_required([:name, :session_id])
  end
end
