defmodule HrBrandAgent.Analysis.RedFlag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "red_flags" do
    field :flag_id, :integer  # 1-7
    field :flag_name, :string
    field :severity, :string  # low, medium, high
    field :frequency, :integer, default: 0
    field :evidence, {:array, :string}, default: []
    field :sources, {:array, :string}, default: []
    field :description, :string

    belongs_to :session, HrBrandAgent.Research.Session

    timestamps()
  end

  @doc false
  def changeset(flag, attrs) do
    flag
    |> cast(attrs, [:flag_id, :flag_name, :severity, :frequency, :evidence, :sources, :description, :session_id])
    |> validate_required([:flag_id, :flag_name, :severity, :session_id])
    |> validate_inclusion(:flag_id, 1..7)
    |> validate_inclusion(:severity, ["low", "medium", "high"])
  end
end
