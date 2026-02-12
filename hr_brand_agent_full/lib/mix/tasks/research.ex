defmodule Mix.Tasks.Research do
  @moduledoc """
  CLI task to start company research.

  ## Examples

      mix research --company "Company Name" --website "https://company.com"
      mix research --company "Company Name" --competitors "Competitor1,Competitor2"
  """

  use Mix.Task

  alias HrBrandAgent.Research
  alias HrBrandAgent.Core.Orchestrator

  @shortdoc "Start research for a company"

  @impl Mix.Task
  def run(args) do
    # Start the application
    Mix.Task.run("app.start")

    # Parse arguments
    {opts, _, _} = OptionParser.parse(args,
      switches: [
        company: :string,
        website: :string,
        industry: :string,
        competitors: :string,
        user_id: :integer
      ],
      aliases: [
        c: :company,
        w: :website,
        i: :industry
      ]
    )

    company_name = opts[:company] || raise "--company is required"
    website = opts[:website]
    industry = opts[:industry] || "web3"
    competitors = parse_competitors(opts[:competitors])
    user_id = opts[:user_id] || 1  # Default to first user

    Mix.shell().info("Starting research for: #{company_name}")
    Mix.shell().info("Industry: #{industry}")
    
    # Create or find company
    company = 
      case Research.get_company_by_name(company_name) do
        nil ->
          {:ok, company} = Research.create_company(%{
            name: company_name,
            website: website,
            industry: industry
          })
          company
          
        existing ->
          existing
      end

    # Create research session
    {:ok, session} = Research.create_session(%{
      company_id: company.id,
      user_id: user_id,
      status: "in_progress",
      data_sources: ["linkedin", "web"],
      started_at: DateTime.utc_now()
    })

    Mix.shell().info("Created research session: #{session.id}")
    Mix.shell().info("Starting data collection...")

    # Run research
    case Orchestrator.start_research(session.id, company, competitors) do
      {:ok, _} ->
        Mix.shell().info("")
        Mix.shell().info("✓ Research completed successfully!")
        Mix.shell().info("")
        Mix.shell().info("View results at: http://localhost:4000/research/#{session.id}/results")
        
      {:error, error} ->
        Mix.shell().error("Research failed: #{inspect(error)}")
        System.halt(1)
    end
  end

  defp parse_competitors(nil), do: []
  defp parse_competitors(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
