defmodule HrBrandAgent.Analysis.HiringFunnel do
  @moduledoc """
  Analyzes three key areas of hiring funnel:
  1. Job description quality
  2. Interview experience
  3. Employer image
  """
  alias HrBrandAgent.Research

  @doc """
  Analyze hiring funnel for a research session.
  """
  def analyze(session_id) do
    # Get all relevant data
    linkedin_data = Research.list_linkedin_data(session_id)
    web_data = Research.list_web_data(session_id)
    telegram_data = Research.list_telegram_data(session_id)
    
    # Extract different data types
    job_posts = extract_job_posts(linkedin_data)
    reviews = extract_reviews(linkedin_data ++ web_data)
    interview_feedback = extract_interview_feedback(web_data ++ telegram_data)
    
    # Analyze each area
    job_analysis = analyze_job_descriptions(job_posts)
    interview_analysis = analyze_interviews(interview_feedback)
    image_analysis = analyze_employer_image(reviews ++ telegram_data)
    
    results = %{
      job_descriptions: job_analysis,
      interview_experience: interview_analysis,
      employer_image: image_analysis,
      overall_score: calculate_overall_score(job_analysis, interview_analysis, image_analysis)
    }
    
    # Save results
    HrBrandAgent.Analysis.upsert_result(session_id, "funnel", results)
    
    results
  end

  # Job Description Analysis
  defp analyze_job_descriptions(job_posts) do
    if length(job_posts) == 0 do
      %{
        score: 0,
        clarity_score: 0,
        transparency_score: 0,
        attractiveness_score: 0,
        issues: ["No job descriptions found"],
        strengths: [],
        recommendations: ["Add clear job descriptions to improve visibility"]
      }
    else
      scores = Enum.map(job_posts, &score_job_post/1)
      
      avg_clarity = scores |> Enum.map(& &1.clarity) |> average()
      avg_transparency = scores |> Enum.map(& &1.transparency) |> average()
      avg_attractiveness = scores |> Enum.map(& &1.attractiveness) |> average()
      
      all_issues = scores |> Enum.flat_map(& &1.issues) |> Enum.uniq()
      all_strengths = scores |> Enum.flat_map(& &1.strengths) |> Enum.uniq()
      
      %{
        score: Float.round((avg_clarity + avg_transparency + avg_attractiveness) / 3, 2),
        clarity_score: Float.round(avg_clarity, 2),
        transparency_score: Float.round(avg_transparency, 2),
        attractiveness_score: Float.round(avg_attractiveness, 2),
        total_jobs_analyzed: length(job_posts),
        issues: all_issues,
        strengths: all_strengths,
        recommendations: generate_job_recommendations(all_issues)
      }
    end
  end

  defp score_job_post(job_post) do
    content = job_post.content || ""
    title = job_post.title || ""
    
    # Check clarity
    has_requirements = String.contains?(String.downcase(content), ["requirements", "skills", "qualifications"])
    has_responsibilities = String.contains?(String.downcase(content), ["responsibilities", "duties", "what you'll do"])
    clarity_score = if has_requirements and has_responsibilities, do: 100, else: 50
    
    # Check transparency
    has_salary = String.contains?(String.downcase(content), ["salary", "compensation", "$", "usd", "eur", "rub"])
    has_benefits = String.contains?(String.downcase(content), ["benefits", "perks", "health insurance", "vacation"])
    transparency_score = cond do
      has_salary and has_benefits -> 100
      has_salary or has_benefits -> 70
      true -> 30
    end
    
    # Check attractiveness
    growth_keywords = ["growth", "development", "learning", "career", "promotion"]
    culture_keywords = ["culture", "team", "collaborative", "innovative", "flexible"]
    
    has_growth = Enum.any?(growth_keywords, &String.contains?(String.downcase(content), &1))
    has_culture = Enum.any?(culture_keywords, &String.contains?(String.downcase(content), &1))
    
    attractiveness_score = cond do
      has_growth and has_culture -> 100
      has_growth or has_culture -> 70
      true -> 40
    end
    
    # Identify issues
    issues = []
    issues = if not has_requirements, do: ["Unclear requirements" | issues], else: issues
    issues = if not has_salary, do: ["No salary information" | issues], else: issues
    issues = if not has_benefits, do: ["No benefits mentioned" | issues], else: issues
    
    # Identify strengths
    strengths = []
    strengths = if has_growth, do: ["Mentions growth opportunities" | strengths], else: strengths
    strengths = if has_culture, do: ["Describes company culture" | strengths], else: strengths
    
    %{
      clarity: clarity_score,
      transparency: transparency_score,
      attractiveness: attractiveness_score,
      issues: issues,
      strengths: strengths
    }
  end

  # Interview Experience Analysis
  defp analyze_interviews(feedback_list) do
    if length(feedback_list) == 0 do
      %{
        score: 0,
        recruiter_score: 0,
        process_score: 0,
        communication_score: 0,
        avg_duration: nil,
        positive_aspects: [],
        negative_aspects: ["No interview feedback found"],
        recommendations: ["Encourage candidates to share interview experiences"]
      }
    else
      scores = Enum.map(feedback_list, &score_interview_feedback/1)
      
      avg_recruiter = scores |> Enum.map(& &1.recruiter_score) |> average()
      avg_process = scores |> Enum.map(& &1.process_score) |> average()
      avg_communication = scores |> Enum.map(& &1.communication_score) |> average()
      
      durations = scores |> Enum.map(& &1.duration) |> Enum.reject(&is_nil/1)
      avg_duration = if length(durations) > 0, do: Float.round(average(durations), 1), else: nil
      
      positive = scores |> Enum.flat_map(& &1.positive) |> Enum.frequencies() |> Enum.sort_by(&elem(&1, 1), :desc) |> Enum.take(5) |> Enum.map(&elem(&1, 0))
      negative = scores |> Enum.flat_map(& &1.negative) |> Enum.frequencies() |> Enum.sort_by(&elem(&1, 1), :desc) |> Enum.take(5) |> Enum.map(&elem(&1, 0))
      
      %{
        score: Float.round((avg_recruiter + avg_process + avg_communication) / 3, 2),
        recruiter_score: Float.round(avg_recruiter, 2),
        process_score: Float.round(avg_process, 2),
        communication_score: Float.round(avg_communication, 2),
        avg_duration_days: avg_duration,
        total_feedback_count: length(feedback_list),
        positive_aspects: positive,
        negative_aspects: negative,
        recommendations: generate_interview_recommendations(negative)
      }
    end
  end

  defp score_interview_feedback(feedback) do
    content = Map.get(feedback, :content) || Map.get(feedback, :message_text) || ""
    downcase = String.downcase(content)
    
    # Check recruiter professionalism
    recruiter_positive = ["professional", "friendly", "helpful", "responsive", "polite"]
    recruiter_negative = ["rude", "unprofessional", "ghosted", "unresponsive", "dismissive"]
    
    recruiter_score = calculate_score(downcase, recruiter_positive, recruiter_negative)
    
    # Check process organization
    process_positive = ["organized", "smooth", "efficient", "well-structured"]
    process_negative = ["disorganized", "chaotic", "long", "slow", "too many rounds"]
    
    process_score = calculate_score(downcase, process_positive, process_negative)
    
    # Check communication
    comm_positive = ["clear communication", "timely updates", "transparent"]
    comm_negative = ["no communication", "no updates", "vague"]
    
    communication_score = calculate_score(downcase, comm_positive, comm_negative)
    
    # Extract duration
    duration = extract_duration(content)
    
    # Extract positive and negative aspects
    positive = 
      recruiter_positive ++ process_positive ++ comm_positive
      |> Enum.filter(&String.contains?(downcase, &1))
    
    negative = 
      recruiter_negative ++ process_negative ++ comm_negative
      |> Enum.filter(&String.contains?(downcase, &1))
    
    %{
      recruiter_score: recruiter_score,
      process_score: process_score,
      communication_score: communication_score,
      duration: duration,
      positive: positive,
      negative: negative
    }
  end

  # Employer Image Analysis
  defp analyze_employer_image(reviews) do
    if length(reviews) == 0 do
      %{
        score: 0,
        attractors: [],
        concerns: ["No reviews found"],
        reputation_score: 0,
        differentiators: [],
        recommendations: ["Encourage employees and candidates to leave reviews"]
      }
    else
      contents = Enum.map(reviews, fn r -> Map.get(r, :content) || Map.get(r, :message_text) || "" end)
      combined_text = Enum.join(contents, " ") |> String.downcase()
      
      # What attracts candidates
      attractors = [
        {"Growth opportunities", ["growth", "career", "development", "learning", "promotion"]},
        {"Remote work", ["remote", "work from home", "flexible", "hybrid"]},
        {"Competitive compensation", ["salary", "compensation", "pay", "benefits", "equity"]},
        {"Innovative technology", ["innovative", "cutting-edge", "modern", "blockchain", "web3"]},
        {"Great culture", ["culture", "team", "collaborative", "friendly", "supportive"]},
        {"Work-life balance", ["balance", "flexible hours", "no overtime"]}
      ]
      
      found_attractors = 
        attractors
        |> Enum.filter(fn {_, keywords} -> 
          Enum.any?(keywords, &String.contains?(combined_text, &1))
        end)
        |> Enum.map(&elem(&1, 0))
      
      # What concerns candidates
      concerns = [
        {"Poor management", ["management", "managers", "disorganized", "micromanagement"]},
        {"Work-life balance issues", ["overtime", "burnout", "stress", "long hours"]},
        {"Low compensation", ["underpaid", "low salary", "cheap", "below market"]},
        {"Toxic culture", ["toxic", "politics", "drama", "unfriendly"]},
        {"High turnover", ["turnover", "people leaving", "exodus"]},
        {"Unclear direction", ["unclear", "direction", "strategy", "vision"]}
      ]
      
      found_concerns = 
        concerns
        |> Enum.filter(fn {_, keywords} -> 
          Enum.any?(keywords, &String.contains?(combined_text, &1))
        end)
        |> Enum.map(&elem(&1, 0))
      
      # Differentiators (unique positive aspects)
      differentiators = identify_differentiators(combined_text, found_attractors)
      
      # Calculate reputation score
      reputation_score = calculate_reputation_score(found_attractors, found_concerns)
      
      %{
        score: reputation_score,
        attractors: found_attractors,
        concerns: found_concerns,
        reputation_score: reputation_score,
        differentiators: differentiators,
        total_reviews_analyzed: length(reviews),
        recommendations: generate_image_recommendations(found_concerns)
      }
    end
  end

  # Helper functions
  defp extract_job_posts(data) do
    Enum.filter(data, &(&1.data_type == "job_post"))
  end

  defp extract_reviews(data) do
    Enum.filter(data, fn d -> 
      d.data_type in ["review", "employee_review"] or Map.get(d, :source) in ["glassdoor", "indeed", "headhunter"]
    end)
  end

  defp extract_interview_feedback(data) do
    Enum.filter(data, fn d ->
      content = Map.get(d, :content) || Map.get(d, :message_text) || ""
      String.contains?(String.downcase(content), ["interview", "hiring process", "recruiter"])
    end)
  end

  defp calculate_score(text, positive_keywords, negative_keywords) do
    positive_count = Enum.count(positive_keywords, &String.contains?(text, &1))
    negative_count = Enum.count(negative_keywords, &String.contains?(text, &1))
    
    base_score = 70
    score = base_score + (positive_count * 10) - (negative_count * 15)
    max(0, min(100, score))
  end

  defp extract_duration(text) do
    # Try to extract duration like "2 weeks", "1 month", "3 days"
    cond do
      Regex.match?(~r/(\d+)\s*week/i, text) ->
        [_, num] = Regex.run(~r/(\d+)\s*week/i, text)
        String.to_integer(num) * 7
        
      Regex.match?(~r/(\d+)\s*month/i, text) ->
        [_, num] = Regex.run(~r/(\d+)\s*month/i, text)
        String.to_integer(num) * 30
        
      Regex.match?(~r/(\d+)\s*day/i, text) ->
        [_, num] = Regex.run(~r/(\d+)\s*day/i, text)
        String.to_integer(num)
        
      true ->
        nil
    end
  end

  defp identify_differentiators(text, attractors) do
    # Web3-specific differentiators
    web3_features = [
      "Token/equity compensation",
      "DAO governance participation",
      "Remote-first culture",
      "Async communication",
      "Open source contribution",
      "Cutting-edge blockchain tech"
    ]
    
    # Filter to only those mentioned
    Enum.filter(web3_features, fn feature ->
      keywords = case feature do
        "Token/equity compensation" -> ["token", "equity", "options"]
        "DAO governance participation" -> ["dao", "governance", "vote"]
        "Remote-first culture" -> ["remote-first", "distributed", "global team"]
        "Async communication" -> ["async", "asynchronous"]
        "Open source contribution" -> ["open source", "github", "oss"]
        "Cutting-edge blockchain tech" -> ["ethereum", "solidity", "smart contract", "defi"]
        _ -> []
      end
      
      Enum.any?(keywords, &String.contains?(text, &1))
    end)
  end

  defp calculate_reputation_score(attractors, concerns) do
    base_score = 70
    attractor_bonus = length(attractors) * 5
    concern_penalty = length(concerns) * 10
    
    max(0, min(100, base_score + attractor_bonus - concern_penalty))
  end

  defp average([]), do: 0.0
  defp average(list), do: Enum.sum(list) / length(list)

  defp calculate_overall_score(job, interview, image) do
    scores = [job.score, interview.score, image.score]
    Float.round(Enum.sum(scores) / length(scores), 2)
  end

  defp generate_job_recommendations(issues) do
    issue_recommendations = %{
      "Unclear requirements" => "Clearly define job requirements and responsibilities",
      "No salary information" => "Include salary range in job postings for transparency",
      "No benefits mentioned" => "Highlight benefits and perks to attract candidates"
    }
    
    Enum.map(issues, &Map.get(issue_recommendations, &1, "Review and improve job descriptions"))
    |> Enum.uniq()
  end

  defp generate_interview_recommendations(negatives) do
    negative_recommendations = %{
      "rude" => "Train recruiters on professional communication",
      "ghosted" => "Implement consistent candidate communication",
      "disorganized" => "Standardize interview process and logistics",
      "slow" => "Streamline hiring process to reduce time-to-hire"
    }
    
    Enum.map(negatives, &Map.get(negative_recommendations, &1, "Improve interview experience"))
    |> Enum.uniq()
  end

  defp generate_image_recommendations(concerns) do
    concern_recommendations = %{
      "Poor management" => "Invest in management training and leadership development",
      "Work-life balance issues" => "Review workloads and promote healthy boundaries",
      "Low compensation" => "Benchmark salaries against market rates",
      "Toxic culture" => "Address cultural issues through team building and values alignment"
    }
    
    Enum.map(concerns, &Map.get(concern_recommendations, &1, "Address employee concerns proactively"))
    |> Enum.uniq()
  end
end
