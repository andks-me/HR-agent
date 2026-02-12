defmodule HrBrandAgent.Analysis do
  @moduledoc """
  The Analysis context.
  """
  import Ecto.Query, warn: false
  alias HrBrandAgent.Repo
  alias HrBrandAgent.Analysis.{Result, RedFlag, Competitor}

  # Analysis Results
  def list_results(session_id) do
    Result
    |> where(session_id: ^session_id)
    |> Repo.all()
  end

  def get_result!(id), do: Repo.get!(Result, id)

  def create_result(attrs) do
    %Result{}
    |> Result.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_result(session_id, analysis_type, results) do
    case Repo.get_by(Result, session_id: session_id, analysis_type: analysis_type) do
      nil ->
        create_result(%{
          session_id: session_id,
          analysis_type: analysis_type,
          results: results,
          generated_at: DateTime.utc_now()
        })

      existing ->
        update_result(existing, %{
          results: results,
          generated_at: DateTime.utc_now()
        })
    end
  end

  def update_result(%Result{} = result, attrs) do
    result
    |> Result.changeset(attrs)
    |> Repo.update()
  end

  # Red Flags
  def list_red_flags(session_id, opts \\ []) do
    RedFlag
    |> where(session_id: ^session_id)
    |> maybe_filter_by_severity(opts[:severity])
    |> order_by(desc: :frequency)
    |> Repo.all()
  end

  def create_red_flag(attrs) do
    %RedFlag{}
    |> RedFlag.changeset(attrs)
    |> Repo.insert()
  end

  def batch_create_red_flags(session_id, flags) do
    Repo.transaction(fn ->
      Enum.each(flags, fn flag_attrs ->
        attrs = Map.put(flag_attrs, :session_id, session_id)
        
        %RedFlag{}
        |> RedFlag.changeset(attrs)
        |> Repo.insert!()
      end)
    end)
  end

  # Competitors
  def list_competitors(session_id) do
    Competitor
    |> where(session_id: ^session_id)
    |> Repo.all()
  end

  def create_competitor(attrs) do
    %Competitor{}
    |> Competitor.changeset(attrs)
    |> Repo.insert()
  end

  def batch_create_competitors(session_id, competitors) do
    Repo.transaction(fn ->
      Enum.each(competitors, fn comp_attrs ->
        attrs = Map.put(comp_attrs, :session_id, session_id)
        
        %Competitor{}
        |> Competitor.changeset(attrs)
        |> Repo.insert!()
      end)
    end)
  end

  # Helper functions
  defp maybe_filter_by_severity(query, nil), do: query
  defp maybe_filter_by_severity(query, severity), do: where(query, severity: ^severity)
end
