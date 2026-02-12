defmodule HrBrandAgent.Analysis.Sentiment do
  @moduledoc """
  Sentiment analysis using Veritaserum (AFINN-based) and optional ML models.
  """
  require Logger

  # Positive keywords for job/career context
  @positive_words [
    "great", "excellent", "amazing", "awesome", "fantastic", "wonderful",
    "good", "best", "love", "happy", "recommend", "perfect", "outstanding",
    "professional", "friendly", "supportive", "helpful", "caring",
    "opportunity", "growth", "career", "development", "learning",
    "innovative", "modern", "flexible", "fair", "transparent",
    "work-life balance", "remote", "benefits", "salary", "compensation"
  ]

  # Negative keywords for job/career context
  @negative_words [
    "terrible", "awful", "horrible", "bad", "worst", "hate", "dislike",
    "disappointed", "unprofessional", "rude", "disrespectful",
    "toxic", "stressful", "burnout", "overworked", "pressure",
    "disorganized", "confusing", "chaotic", "mismanaged",
    "unfair", "discrimination", "bias", "unethical",
    "low salary", "underpaid", "cheap", "exploitation",
    "nightmare", "avoid", "regret", "quit", "leave", "fired"
  ]

  @doc """
  Analyze text and return sentiment with percentages.
  """
  def analyze_text(text) when is_binary(text) do
    # Use Veritaserum as primary analyzer
    score = Veritaserum.analyze(text)
    
    # Calculate normalized score (-1 to 1)
    normalized_score = normalize_score(score)
    
    # Calculate percentages
    {positive_pct, neutral_pct, negative_pct} = calculate_percentages(normalized_score)
    
    # Determine overall sentiment
    sentiment = classify_sentiment(normalized_score)
    
    # Calculate confidence
    confidence = calculate_confidence(score, text)
    
    %{
      sentiment: sentiment,
      score: score,
      normalized_score: normalized_score,
      percentages: %{
        positive: positive_pct,
        neutral: neutral_pct,
        negative: negative_pct
      },
      confidence: confidence,
      keywords_found: extract_keywords(text)
    }
  end

  def analyze_text(nil), do: analyze_text("")

  @doc """
  Analyze multiple texts and aggregate results.
  """
  def analyze_batch(texts) when is_list(texts) do
    results = Enum.map(texts, &analyze_text/1)
    
    # Aggregate percentages
    total = length(results)
    
    positive_avg = results |> Enum.map(& &1.percentages.positive) |> average()
    neutral_avg = results |> Enum.map(& &1.percentages.neutral) |> average()
    negative_avg = results |> Enum.map(& &1.percentages.negative) |> average()
    
    # Count sentiments
    sentiment_counts = Enum.frequencies_by(results, & &1.sentiment)
    
    %{
      total_analyzed: total,
      average_percentages: %{
        positive: Float.round(positive_avg, 2),
        neutral: Float.round(neutral_avg, 2),
        negative: Float.round(negative_avg, 2)
      },
      sentiment_counts: sentiment_counts,
      average_confidence: results |> Enum.map(& &1.confidence) |> average() |> Float.round(2)
    }
  end

  @doc """
  Analyze all data for a research session.
  """
  def analyze_session(session_id) do
    # Get all text data from session
    linkedin_texts = 
      HrBrandAgent.Research.list_linkedin_data(session_id)
      |> Enum.map(& &1.content)
      |> Enum.reject(&is_nil/1)
    
    telegram_texts =
      HrBrandAgent.Research.list_telegram_data(session_id)
      |> Enum.map(& &1.message_text)
      |> Enum.reject(&is_nil/1)
    
    web_texts =
      HrBrandAgent.Research.list_web_data(session_id)
      |> Enum.map(& &1.content)
      |> Enum.reject(&is_nil/1)
    
    # Analyze by source
    linkedin_analysis = analyze_batch(linkedin_texts)
    telegram_analysis = analyze_batch(telegram_texts)
    web_analysis = analyze_batch(web_texts)
    
    # Calculate overall
    all_texts = linkedin_texts ++ telegram_texts ++ web_texts
    overall = analyze_batch(all_texts)
    
    results = %{
      overall: overall,
      by_source: %{
        linkedin: linkedin_analysis,
        telegram: telegram_analysis,
        web: web_analysis
      }
    }
    
    # Save results
    HrBrandAgent.Analysis.upsert_result(session_id, "sentiment", results)
    
    # Update sentiment scores in data records
    update_sentiment_scores(session_id, linkedin_texts, :linkedin)
    update_sentiment_scores(session_id, telegram_texts, :telegram)
    update_sentiment_scores(session_id, web_texts, :web)
    
    results
  end

  # Private functions
  defp normalize_score(score) when score > 10, do: 1.0
  defp normalize_score(score) when score < -10, do: -1.0
  defp normalize_score(score), do: score / 10.0

  defp calculate_percentages(normalized) do
    # Use exponential normalization for smoother distribution
    exp_pos = :math.exp(normalized * 2)
    exp_neg = :math.exp(-normalized * 2)
    exp_neu = 1.0  # neutral baseline
    
    total = exp_pos + exp_neg + exp_neu
    
    {
      Float.round(exp_pos / total * 100, 2),
      Float.round(exp_neu / total * 100, 2),
      Float.round(exp_neg / total * 100, 2)
    }
  end

  defp classify_sentiment(score) when score >= 0.1, do: :positive
  defp classify_sentiment(score) when score <= -0.1, do: :negative
  defp classify_sentiment(_), do: :neutral

  defp calculate_confidence(score, text) do
    # Base confidence on score magnitude
    magnitude_confidence = min(abs(score) / 5.0, 1.0)
    
    # Adjust for text length
    word_count = text |> String.split() |> length()
    length_factor = min(word_count / 5.0, 1.0)
    
    # Combine factors
    Float.round((magnitude_confidence * 0.7 + length_factor * 0.3) * 100, 2)
  end

  defp extract_keywords(text) do
    downcase_text = String.downcase(text)
    
    found_positive = Enum.filter(@positive_words, &String.contains?(downcase_text, &1))
    found_negative = Enum.filter(@negative_words, &String.contains?(downcase_text, &1))
    
    %{
      positive: found_positive,
      negative: found_negative
    }
  end

  defp average([]), do: 0.0
  defp average(list), do: Enum.sum(list) / length(list)

  defp update_sentiment_scores(_session_id, [], _source), do: :ok
  defp update_sentiment_scores(session_id, texts, source) do
    # This would update the records with sentiment scores
    # Implementation depends on how you want to store individual scores
    :ok
  end
end
