defmodule HrBrandAgent.Analysis.Competitors do
  @moduledoc """
  Compares target company against Web-3 competitors.
  """
  alias HrBrandAgent.Research
  alias HrBrandAgent.Analysis

  @web3_keywords [
    "blockchain", "crypto", "web3", "defi", "nft",
    "ethereum", "bitcoin", "solidity", "smart contract", "dao",
    "layer 2", "rollup", "bridge", "protocol", "dapp"
  ]

  @doc """
  Analyze competitors for a research session.
  """
  def analyze(session_id, target_company_id, competitor_names) do
    target_company = Research.get_company!(target_company_id)
    
    # Auto-discover competitors if none provided
    competitors = 
      if length(competitor_names) == 0 do
        auto_discover_competitors(target_company)
      else
        Enum.map(competitor_names, &%{name: &1, website: nil})
      end
    
    # Analyze each competitor
    competitor_analyses = 
      Enum.map(competitors, fn comp ->
        analyze_competitor(comp, target_company)
      end)
    
    # Save competitors
    competitor_attrs = 
      Enum.map(competitor_analyses, fn analysis ->
        %{
          name: analysis.name,
          website: analysis.website,
          industry: "web3",
          comparison_data: analysis,
          reputation_score: analysis.reputation_score
        }
      end)
    
    Analysis.batch_create_competitors(session_id, competitor_attrs)
    
    # Generate comparison report
    report = %{
      target_company: target_company.name,
      competitors_analyzed: length(competitor_analyses),
      market_position: calculate_market_position(competitor_analyses),
      competitive_advantages: identify_advantages(competitor_analyses),
      competitive_disadvantages: identify_disadvantages(competitor_analyses),
      benchmarks: calculate_benchmarks(competitor_analyses),
      detailed_comparison: competitor_analyses,
      recommendations: generate_competitive_recommendations(competitor_analyses)
    }
    
    # Save report
    Analysis.upsert_result(session_id, "competitors", report)
    
    report
  end

  @doc """
  Auto-discover Web-3 competitors based on industry and keywords.
  """
  def auto_discover_competitors(target_company) do
    # This is a simplified version - in production, you'd use:
    # - Web scraping of industry lists
    # - API integrations (Crunchbase, AngelList)
    # - LLM queries for competitor discovery
    
    # Common Web-3 companies as examples
    common_web3 = [
      %{name: "OpenSea", website: "https://opensea.io", focus: "NFT Marketplace"},
      %{name: "Uniswap", website: "https://uniswap.org", focus: "DEX"},
      %{name: "Aave", website: "https://aave.com", focus: "DeFi Lending"},
      %{name: "Polygon", website: "https://polygon.technology", focus: "Layer 2"},
      %{name: "Chainlink", website: "https://chain.link", focus: "Oracle"},
      %{name: "ConsenSys", website: "https://consensys.net", focus: "Ethereum Tools"}
    ]
    
    # Return up to 5 random competitors (in production, use intelligent matching)
    Enum.take_random(common_web3, 5)
  end

  # Private functions
  defp analyze_competitor(competitor, target_company) do
    # Simulate competitor analysis (in production, you'd actually research these)
    # This would involve:
    # - Scraping their job postings
    # - Analyzing their reviews
    # - Comparing benefits and compensation
    # - Researching their interview process
    
    %{
      name: competitor.name,
      website: competitor.website,
      focus: Map.get(competitor, :focus, "Web3"),
      
      # Simulated scores (0-100)
      salary_competitiveness: random_score(60, 95),
      benefits_score: random_score(50, 90),
      remote_flexibility: random_score(70, 100),
      interview_difficulty: random_score(40, 80),
      reputation_score: random_score(50, 95),
      
      # Comparison to target
      comparison: %{
        salary_vs_target: random_comparison(),
        benefits_vs_target: random_comparison(),
        culture_vs_target: random_comparison()
      },
      
      # Key differentiators
      strengths: random_strengths(),
      weaknesses: random_weaknesses(),
      
      # Tech stack (for Web3)
      tech_stack: random_web3_stack(),
      
      # Hiring signals
      hiring_volume: random_hiring_volume(),
      growth_trajectory: random_trajectory()
    }
  end

  defp calculate_market_position(competitor_analyses) do
    scores = Enum.map(competitor_analyses, & &1.reputation_score)
    avg_competitor_score = if length(scores) > 0, do: Enum.sum(scores) / length(scores), else: 70
    
    # Assume target company has average score
    target_score = 75
    
    cond do
      target_score > avg_competitor_score + 10 -> "Leader"
      target_score > avg_competitor_score -> "Above Average"
      target_score < avg_competitor_score - 10 -> "Challenger"
      true -> "Average"
    end
  end

  defp identify_advantages(competitor_analyses) do
    # Identify areas where target can differentiate
    low_competitor_scores = 
      competitor_analyses
      |> Enum.filter(&(&1.remote_flexibility < 80))
      |> length()
    
    advantages = []
    advantages = if low_competitor_scores >= 3, do: ["Remote-first culture" | advantages], else: advantages
    
    # Add more advantage detection logic here
    
    advantages
  end

  defp identify_disadvantages(competitor_analyses) do
    # Identify areas where competitors are stronger
    high_salary_count = Enum.count(competitor_analyses, &(&1.salary_competitiveness > 85))
    
    disadvantages = []
    disadvantages = if high_salary_count >= 3, do: ["Salary competitiveness" | disadvantages], else: disadvantages
    
    disadvantages
  end

  defp calculate_benchmarks(competitor_analyses) do
    if length(competitor_analyses) == 0 do
      %{}
    else
      %{
        avg_salary_score: average_by_key(competitor_analyses, :salary_competitiveness),
        avg_benefits_score: average_by_key(competitor_analyses, :benefits_score),
        avg_remote_flexibility: average_by_key(competitor_analyses, :remote_flexibility),
        avg_interview_difficulty: average_by_key(competitor_analyses, :interview_difficulty),
        avg_reputation: average_by_key(competitor_analyses, :reputation_score)
      }
    end
  end

  defp generate_competitive_recommendations(competitor_analyses) do
    recommendations = []
    
    # Check for salary gaps
    avg_salary = average_by_key(competitor_analyses, :salary_competitiveness)
    recommendations = if avg_salary > 80, do: ["Review salary bands to remain competitive" | recommendations], else: recommendations
    
    # Check for remote work trends
    remote_scores = Enum.map(competitor_analyses, & &1.remote_flexibility)
    high_remote = Enum.count(remote_scores, &(&1 >= 90))
    recommendations = if high_remote >= 3, do: ["Emphasize remote work options in job postings" | recommendations], else: recommendations
    
    recommendations
  end

  # Helper functions
  defp random_score(min, max) do
    min + :rand.uniform(max - min)
  end

  defp random_comparison do
    [:stronger, :weaker, :similar] |> Enum.random()
  end

  defp random_strengths do
    possible = [
      "Strong technical team",
      "High compensation",
      "Remote-first culture",
      "Innovative technology",
      "Fast hiring process",
      "Great benefits"
    ]
    
    Enum.take_random(possible, 3)
  end

  defp random_weaknesses do
    possible = [
      "Long hiring process",
      "Limited remote options",
      "Below-market salaries",
      "High turnover",
      "Poor Glassdoor ratings"
    ]
    
    Enum.take_random(possible, 2)
  end

  defp random_web3_stack do
    possible = ["Ethereum", "Solidity", "Rust", "Go", "React", "Node.js", "IPFS"]
    Enum.take_random(possible, 4)
  end

  defp random_hiring_volume do
    [:high, :medium, :low] |> Enum.random()
  end

  defp random_trajectory do
    [:growing, :stable, :declining] |> Enum.random()
  end

  defp average_by_key(list, key) do
    values = Enum.map(list, &Map.get(&1, key, 0))
    Float.round(Enum.sum(values) / length(values), 2)
  end
end
