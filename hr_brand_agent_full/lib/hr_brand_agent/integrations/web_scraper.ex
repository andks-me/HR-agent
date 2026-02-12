defmodule HrBrandAgent.Integrations.WebScraper do
  @moduledoc """
  Web scraper for Glassdoor, Indeed, HeadHunter, and other job/review sites.
  """
  require Logger

  @user_agents [
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
  ]

  def scrape_glassdoor(company_name, opts \\ []) do
    search_url = "https://www.glassdoor.com/Reviews/#{URI.encode(company_name)}-reviews.htm"
    
    case fetch_page(search_url) do
      {:ok, html} ->
        reviews = parse_glassdoor_reviews(html)
        {:ok, reviews}
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  def scrape_indeed(company_name, opts \\ []) do
    search_url = "https://www.indeed.com/cmp/#{URI.encode(company_name)}/reviews"
    
    case fetch_page(search_url) do
      {:ok, html} ->
        reviews = parse_indeed_reviews(html)
        {:ok, reviews}
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  def scrape_headhunter(company_name, opts \\ []) do
    # HeadHunter (hh.ru) is Russian job site
    search_url = "https://hh.ru/employer/#{URI.encode(company_name)}"
    
    case fetch_page(search_url) do
      {:ok, html} ->
        reviews = parse_headhunter_reviews(html)
        {:ok, reviews}
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_page(url, retries \\ 3) do
    headers = [
      {"User-Agent", Enum.random(@user_agents)},
      {"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
      {"Accept-Language", "en-US,en;q=0.9"},
      {"Accept-Encoding", "gzip, deflate, br"},
      {"Connection", "keep-alive"}
    ]

    case Req.get(url, headers: headers, max_redirects: 5) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}
        
      {:ok, %{status: status}} when status in [301, 302, 307, 308] ->
        {:error, :redirect}
        
      {:ok, %{status: 429}} ->
        if retries > 0 do
          Logger.warning("Rate limited, waiting...")
          Process.sleep(5000)
          fetch_page(url, retries - 1)
        else
          {:error, :rate_limited}
        end
        
      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}
        
      {:error, reason} ->
        if retries > 0 do
          Process.sleep(1000)
          fetch_page(url, retries - 1)
        else
          {:error, reason}
        end
    end
  end

  defp parse_glassdoor_reviews(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        document
        |> Floki.find(".review")
        |> Enum.map(fn review ->
          %{
            source: "glassdoor",
            author: extract_text(review, ".authorInfo"),
            job_title: extract_text(review, ".authorJobTitle"),
            rating: extract_rating(review, ".ratingNumber"),
            content: extract_text(review, ".review-text"),
            pros: extract_text(review, ".pros"),
            cons: extract_text(review, ".cons"),
            review_date: extract_date(review, ".date"),
            metadata: %{}
          }
        end)
        
      {:error, _} ->
        []
    end
  end

  defp parse_indeed_reviews(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        document
        |> Floki.find("[data-testid='review-container']")
        |> Enum.map(fn review ->
          %{
            source: "indeed",
            author: extract_text(review, "[data-testid='review-author']"),
            job_title: extract_text(review, "[data-testid='review-job-title']"),
            rating: extract_rating(review, "[data-testid='review-rating']"),
            content: extract_text(review, "[data-testid='review-text']"),
            review_date: extract_date(review, "[data-testid='review-date']"),
            metadata: %{}
          }
        end)
        
      {:error, _} ->
        []
    end
  end

  defp parse_headhunter_reviews(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        document
        |> Floki.find(".employer-review")
        |> Enum.map(fn review ->
          %{
            source: "headhunter",
            author: extract_text(review, ".employer-review__author"),
            job_title: extract_text(review, ".employer-review__position"),
            rating: extract_rating(review, ".employer-review__rating"),
            content: extract_text(review, ".employer-review__text"),
            review_date: extract_date(review, ".employer-review__date"),
            metadata: %{}
          }
        end)
        
      {:error, _} ->
        []
    end
  end

  defp extract_text(element, selector) do
    element
    |> Floki.find(selector)
    |> Floki.text()
    |> String.trim()
  end

  defp extract_rating(element, selector) do
    element
    |> Floki.find(selector)
    |> Floki.text()
    |> parse_rating()
  end

  defp parse_rating(text) do
    case Regex.run(~r/([\d.]+)/, text) do
      [_, rating] -> 
        case Float.parse(rating) do
          {num, _} -> num
          :error -> nil
        end
      _ -> nil
    end
  end

  defp extract_date(element, selector) do
    text = extract_text(element, selector)
    
    # Try to parse various date formats
    case parse_date(text) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_date(text) do
    # Common formats: "Jan 15, 2024", "2024-01-15", "15 January 2024"
    formats = [
      "%b %d, %Y",
      "%Y-%m-%d",
      "%d %B %Y",
      "%d.%m.%Y"
    ]
    
    Enum.find_value(formats, fn format ->
      case Timex.parse(text, format, :strftime) do
        {:ok, datetime} -> {:ok, datetime}
        _ -> nil
      end
    end) || {:error, :invalid_format}
  end
end
