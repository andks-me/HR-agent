defmodule HrBrandAgent.Research do
  @moduledoc """
  The Research context.
  """
  import Ecto.Query, warn: false
  alias HrBrandAgent.Repo
  alias HrBrandAgent.Research.{Company, Session, LinkedinData, TelegramData, WebData, AIQuery}

  # Company CRUD
  def list_companies(opts \\ []) do
    Company
    |> maybe_filter_by_industry(opts[:industry])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_company!(id), do: Repo.get!(Company, id)
  def get_company_by_name(name), do: Repo.get_by(Company, name: name)

  def create_company(attrs) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  def update_company(%Company{} = company, attrs) do
    company
    |> Company.changeset(attrs)
    |> Repo.update()
  end

  def delete_company(%Company{} = company) do
    Repo.delete(company)
  end

  # Session CRUD
  def list_sessions(opts \\ []) do
    Session
    |> maybe_filter_by_status(opts[:status])
    |> maybe_filter_by_user(opts[:user_id])
    |> preload(:company)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_session!(id) do
    Session
    |> Repo.get!(id)
    |> Repo.preload([:company, :linkedin_data, :telegram_data, :web_data, :analysis_results, :red_flags, :competitors])
  end

  def create_session(attrs) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  def update_session(%Session{} = session, attrs) do
    session
    |> Session.changeset(attrs)
    |> Repo.update()
  end

  def delete_session(%Session{} = session) do
    Repo.delete(session)
  end

  # LinkedIn Data
  def create_linkedin_data(attrs) do
    %LinkedinData{}
    |> LinkedinData.changeset(attrs)
    |> Repo.insert()
  end

  def list_linkedin_data(session_id) do
    LinkedinData
    |> where(session_id: ^session_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # Telegram Data
  def create_telegram_data(attrs) do
    %TelegramData{}
    |> TelegramData.changeset(attrs)
    |> Repo.insert()
  end

  def list_telegram_data(session_id) do
    TelegramData
    |> where(session_id: ^session_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # Web Data
  def create_web_data(attrs) do
    %WebData{}
    |> WebData.changeset(attrs)
    |> Repo.insert()
  end

  def list_web_data(session_id) do
    WebData
    |> where(session_id: ^session_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # AI Queries
  def create_ai_query(attrs) do
    %AIQuery{}
    |> AIQuery.changeset(attrs)
    |> Repo.insert()
  end

  def list_ai_queries(session_id) do
    AIQuery
    |> where(session_id: ^session_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # Helper functions
  defp maybe_filter_by_industry(query, nil), do: query
  defp maybe_filter_by_industry(query, industry), do: where(query, industry: ^industry)

  defp maybe_filter_by_status(query, nil), do: query
  defp maybe_filter_by_status(query, status), do: where(query, status: ^status)

  defp maybe_filter_by_user(query, nil), do: query
  defp maybe_filter_by_user(query, user_id), do: where(query, user_id: ^user_id)
end
