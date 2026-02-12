defmodule HrBrandAgent.Analysis.RedFlags do
  @moduledoc """
  Detects 7 main red flags that cause candidates to reject offers.
  """
  alias HrBrandAgent.Research
  alias HrBrandAgent.Analysis

  @red_flags [
    %{
      id: 1,
      name: "unclear_requirements",
      display_name: "Unclear Job Requirements",
      keywords: ["vague", "unclear", "confusing requirements", "contradictory", "not specified"],
      description: "Job descriptions lack clarity about requirements and expectations"
    },
    %{
      id: 2,
      name: "unprofessional_recruiters",
      display_name: "Unprofessional Recruiters",
      keywords: ["rude", "unprofessional", "ghosted", "ignored", "dismissive", "arrogant"],
      description: "Recruiters demonstrate unprofessional behavior during hiring process"
    },
    %{
      id: 3,
      name: "salary_mismatch",
      display_name: "Salary/Compensation Issues",
      keywords: ["low salary", "underpaid", "below market", "unfair pay", "compensation issues", "low pay"],
      description: "Compensation does not match market rates or candidate expectations"
    },
    %{
      id: 4,
      name: "long_hiring_process",
      display_name: "Overly Long Hiring Process",
      keywords: ["too many rounds", "endless", "dragging", "slow process", "took forever", "months"],
      description: "Hiring process takes too long with excessive interview rounds"
    },
    %{
      id: 5,
      name: "toxic_culture",
      display_name: "Toxic Workplace Culture",
      keywords: ["toxic", "burnout", "overworked", "no work-life balance", "high turnover", "stressful"],
      description: "Indicators of poor work-life balance and toxic environment"
    },
    %{
      id: 6,
      name: "lack_transparency",
      display_name: "Lack of Transparency",
      keywords: ["not transparent", "hidden", "misleading", "false promises", "unclear role", "bait and switch"],
      description: "Company lacks transparency about role, expectations, or conditions"
    },
    %{
      id: 7,
      name: "poor_employer_brand",
      display_name: "Poor Employer Brand",
      keywords: ["bad reputation", "negative reviews", "wouldn't recommend", "stay away", "avoid"],
      description: "Negative overall reputation as an employer"
    }
  ]

  @doc """
  Analyze and detect red flags for a research session.
  """
  def analyze(session_id) do
    # Get all text data
    all_data = 
      Research.list_linkedin_data(session_id) ++
      Research.list_telegram_data(session_id) ++
      Research.list_web_data(session_id)
    
    # Extract all text content
    texts = 
      all_data
      |> Enum.map(fn d -> 
        Map.get(d, :content) || Map.get(d, :message_text) || ""
      end)
      |> Enum.reject(&(&1 == ""))
    
    # Detect each red flag
    detected_flags = 
      @red_flags
      |> Enum.map(fn flag -> detect_flag(flag, texts, all_data)
      |> Enum.filter(fn flag -> flag.frequency > 0 end)
      |> Enum.sort_by(& &1.frequency, :desc)
    
    # Save red flags to database
    Analysis.batch_create_red_flags(session_id, detected_flags)
    
    # Calculate summary
    summary = %{
      total_flags_detected: length(detected_flags),
      high_severity_count: Enum.count(detected_flags, &(&1.severity == "high")),
      medium_severity_count: Enum.count(detected_flags, &(&1.severity == "medium")),
      low_severity_count: Enum.count(detected_flags, &(&1.severity == "low")),
      flags: detected_flags,
      overall_risk_score: calculate_risk_score(detected_flags),
      recommendations: generate_recommendations(detected_flags)
    }
    
    # Save summary as analysis result
    Analysis.upsert_result(session_id, "red_flags", summary)
    
    summary
  end

  @doc """
  Get all red flag definitions.
  """
  def list_red_flag_definitions do
    @red_flags
  end

  # Private functions
  defp detect_flag(flag_config, texts, all_data) do
    # Find all mentions
    mentions = 
      texts
      |> Enum.with_index()
      |> Enum.filter(fn {text, _idx} ->
        downcase_text = String.downcase(text)
        Enum.any?(flag_config.keywords, &String.contains?(downcase_text, &1))
      end)
    
    # Get evidence (actual text snippets)
    evidence = 
      mentions
      |> Enum.map(fn {text, _idx} -> text end)
      |> Enum.take(5)  # Limit to 5 examples
    
    # Identify sources
    sources = 
      mentions
      |> Enum.map(fn {_text, idx} -> 
        data = Enum.at(all_data, idx)
        source_from_data(data)
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
    
    frequency = length(mentions)
    
    %{
      flag_id: flag_config.id,
      flag_name: flag_config.display_name,
      severity: calculate_severity(frequency, length(texts)),
      frequency: frequency,
      evidence: evidence,
      sources: sources,
      description: flag_config.description
    }
  end

  defp source_from_data(%{data_type: type}) when type in ["review", "employee_review"], do: "LinkedIn"
  defp source_from_data(%{source: source}) when is_binary(source), do: String.capitalize(source)
  defp source_from_data(%{chat_name: name}) when is_binary(name), do: "Telegram: #{name}"
  defp source_from_data(_), do: nil

  defp calculate_severity(mentions_count, total_texts) do
    ratio = mentions_count / max(total_texts, 1)
    
    cond do
      ratio > 0.15 or mentions_count >= 10 -> "high"
      ratio > 0.05 or mentions_count >= 5 -> "medium"
      mentions_count > 0 -> "low"
      true -> "none"
    end
  end

  defp calculate_risk_score(flags) do
    if length(flags) == 0 do
      0
    else
      base_score = 100
      
      deductions = 
        Enum.reduce(flags, 0, fn flag, acc ->
          severity_weight = case flag.severity do
            "high" -> 15
            "medium" -> 8
            "low" -> 3
            _ -> 0
          end
          
          frequency_weight = min(flag.frequency * 2, 10)
          
          acc + severity_weight + frequency_weight
        end)
      
      max(0, base_score - deductions)
    end
  end

  defp generate_recommendations(flags) do
    recommendations_map = %{
      "unclear_requirements" => "Review and clarify job descriptions with specific requirements",
      "unprofessional_recruiters" => "Provide recruiter training on professional communication",
      "salary_mismatch" => "Benchmark compensation against market rates and be transparent",
      "long_hiring_process" => "Streamline interview process and set clear timeline expectations",
      "toxic_culture" => "Address cultural issues through leadership and team initiatives",
      "lack_transparency" => "Improve transparency about role expectations and company conditions",
      "poor_employer_brand" => "Develop employer branding strategy and address negative feedback"
    }
    
    flags
    |> Enum.map(& &1.flag_name)
    |> Enum.map(fn name ->
      key = name |> String.downcase() |> String.replace(" ", "_")
      Map.get(recommendations_map, key, "Address concerns related to #{name}")
    end)
    |> Enum.uniq()
  end
end
