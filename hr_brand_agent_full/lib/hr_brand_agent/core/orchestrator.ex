defmodule HrBrandAgent.Core.Orchestrator do
  @moduledoc """
  Central orchestrator that coordinates all research activities.
  """
  alias HrBrandAgent.Research
  alias HrBrandAgent.Analysis
  alias HrBrandAgent.Integrations

  require Logger

  @doc """
  Start research for a company.
  """
  def start_research(session_id, company, competitor_names) do
    Logger.info("Starting research for #{company.name} (session: #{session_id})")
    
    # Update session status
    Research.update_session(
      Research.get_session!(session_id),
      %{status: "in_progress"}
    )
    
    try do
      # 1. Collect LinkedIn data
      Logger.info("Collecting LinkedIn data...")
      collect_linkedin_data(session_id, company)
      
      # 2. Collect Web data
      Logger.info("Collecting Web data...")
      collect_web_data(session_id, company)
      
      # 3. Run analysis
      Logger.info("Running analysis...")
      run_analysis(session_id)
      
      # 4. Analyze competitors
      if length(competitor_names) > 0 do
        Logger.info("Analyzing competitors...")
        Analysis.Competitors.analyze(session_id, company.id, competitor_names)
      end
      
      # 5. Update session as completed
      Research.update_session(
        Research.get_session!(session_id),
        %{
          status: "completed",
          completed_at: DateTime.utc_now()
        }
      )
      
      Logger.info("Research completed for #{company.name}")
      
      # Broadcast completion
      Phoenix.PubSub.broadcast(
        HrBrandAgent.PubSub,
        "research:#{session_id}",
        {:research_completed, session_id}
      )
      
      {:ok, session_id}
      
    rescue
      error ->
        Logger.error("Research failed: #{inspect(error)}")
        
        Research.update_session(
          Research.get_session!(session_id),
          %{status: "failed"}
        )
        
        {:error, error}
    end
  end

  # Data collection functions
  defp collect_linkedin_data(session_id, company) do
    # Get LinkedIn credentials
    linkedin_config = Application.get_env(:hr_brand_agent, :linkedin)
    
    if linkedin_config[:email] && linkedin_config[:password] do
      # Login and research
      case Integrations.LinkedIn.Browser.login(
        linkedin_config[:email],
        linkedin_config[:password]
      ) do
        :ok ->
          # Get company info
          case Integrations.LinkedIn.Browser.research_company(
            company.name,
            company.linkedin_url
          ) do
            {:ok, company_info} ->
              # Save company info
              Research.create_linkedin_data(%{
                session_id: session_id,
                data_type: "company_info",
                content: company_info[:description],
                metadata: company_info
              })
              
              # Get jobs
              case Integrations.LinkedIn.Browser.get_job_descriptions(company.name) do
                {:ok, jobs} ->
                  Enum.each(jobs, fn job ->
                    Research.create_linkedin_data(%{
                      session_id: session_id,
                      data_type: "job_post",
                      title: job[:title],
                      content: "#{job[:company]} - #{job[:location]}",
                      url: job[:url],
                      metadata: job
                    })
                  end)
                
                {:error, _} -> :ok
              end
              
            {:error, _} ->
              :ok
          end
          
          # Close session
          Integrations.LinkedIn.Browser.close_session()
          
        {:error, _} ->
          :ok
      end
    else
      Logger.warning("LinkedIn credentials not configured")
    end
  end

  defp collect_web_data(session_id, company) do
    # Scrape various sources
    sources = [
      {:glassdoor, &Integrations.WebScraper.scrape_glassdoor/1},
      {:indeed, &Integrations.WebScraper.scrape_indeed/1},
      {:headhunter, &Integrations.WebScraper.scrape_headhunter/1}
    ]
    
    Enum.each(sources, fn {source_name, scraper_fn} ->
      case scraper_fn.(company.name) do
        {:ok, reviews} ->
          Enum.each(reviews, fn review ->
            Research.create_web_data(%{
              session_id: session_id,
              source: to_string(source_name),
              content: review[:content],
              author: review[:author],
              rating: review[:rating],
              job_title: review[:job_title],
              review_date: review[:review_date],
              metadata: review
            })
          end)
        
        {:error, reason} ->
          Logger.warning("Failed to scrape #{source_name}: #{inspect(reason)}")
      end
    end)
  end

  # Analysis functions
  defp run_analysis(session_id) do
    # Sentiment analysis
    Logger.info("Running sentiment analysis...")
    Analysis.Sentiment.analyze_session(session_id)
    
    # Hiring funnel analysis
    Logger.info("Running hiring funnel analysis...")
    Analysis.HiringFunnel.analyze(session_id)
    
    # Red flags detection
    Logger.info("Running red flags detection...")
    Analysis.RedFlags.analyze(session_id)
    
    :ok
  end
end
