defmodule HrBrandAgent.Research.TelegramData do
  use Ecto.Schema
  import Ecto.Changeset

  schema "telegram_data" do
    field :chat_name, :string
    field :chat_id, :integer
    field :message_text, :string
    field :sender, :string
    field :sender_id, :integer
    field :message_date, :utc_datetime
    field :sentiment_score, :float
    field :is_about_company, :boolean, default: false
    field :is_about_competitor, :boolean, default: false
    field :keywords, {:array, :string}, default: []
    field :metadata, :map, default: %{}

    belongs_to :session, HrBrandAgent.Research.Session

    timestamps()
  end

  @doc false
  def changeset(data, attrs) do
    data
    |> cast(attrs, [:chat_name, :chat_id, :message_text, :sender, :sender_id, :message_date, :sentiment_score, :is_about_company, :is_about_competitor, :keywords, :metadata, :session_id])
    |> validate_required([:session_id])
  end
end
