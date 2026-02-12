defmodule HrBrandAgent.Research.Company do
  use Ecto.Schema
  import Ecto.Changeset

  schema "companies" do
    field :name, :string
    field :website, :string
    field :industry, :string, default: "web3"
    field :linkedin_url, :string
    field :description, :string
    field :employee_count, :string
    field :founded, :string
    field :headquarters, :string
    field :metadata, :map, default: %{}

    has_many :research_sessions, HrBrandAgent.Research.Session

    timestamps()
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :website, :industry, :linkedin_url, :description, :employee_count, :founded, :headquarters, :metadata])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 255)
    |> validate_format(:website, ~r/^https?:\/\//, message: "must start with http:// or https://")
    |> unique_constraint(:name)
  end
end
