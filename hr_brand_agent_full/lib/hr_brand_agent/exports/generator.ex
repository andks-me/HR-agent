defmodule HrBrandAgent.Exports.Generator do
  @moduledoc """
  Generates export files (HTML, PDF, CSV) for research results.
  """
  alias HrBrandAgent.Research
  alias HrBrandAgent.Analysis
  alias HrBrandAgent.Storage.Cloud

  require Logger

  @doc """
  Generate CSV export for a research session.
  """
  def generate_csv(session_id) do
    session = Research.get_session!(session_id)
    
    # Get all data
    linkedin_data = Research.list_linkedin_data(session_id)
    telegram_data = Research.list_telegram_data(session_id)
    web_data = Research.list_web_data(session_id)
    red_flags = Analysis.list_red_flags(session_id)
    
    # Build CSV content
    csv_rows = [
      ["Research Report for #{session.company.name}"],
      ["Generated:", DateTime.utc_now() |> DateTime.to_string()],
      [""],
      ["SENTIMENT ANALYSIS"],
      ["Source", "Positive %", "Neutral %", "Negative %"],
      # Add sentiment data...
      [""],
      ["RED FLAGS DETECTED"],
      ["Flag", "Severity", "Frequency", "Description"]
    ]
    
    red_flag_rows = Enum.map(red_flags, fn flag ->
      [flag.flag_name, flag.severity, flag.frequency, flag.description]
    end)
    
    csv_rows = csv_rows ++ red_flag_rows ++ [
      [""],
      ["LINKEDIN DATA"],
      ["Type", "Title", "Content", "Sentiment"]
    ]
    
    linkedin_rows = Enum.map(linkedin_data, fn data ->
      [data.data_type, data.title || "", String.slice(data.content || "", 0, 200), data.sentiment_score || ""]
    end)
    
    csv_rows = csv_rows ++ linkedin_rows
    
    # Convert to CSV
    csv_content = csv_rows
    |> CSV.encode()
    |> Enum.join("\n")
    
    # Save to file
    filename = "research_#{session_id}_#{DateTime.utc_now() |> DateTime.to_unix()}.csv"
    local_path = Path.join(System.tmp_dir!(), filename)
    File.write!(local_path, csv_content)
    
    # Upload to cloud
    remote_path = "exports/#{session.user_id}/#{filename}"
    case Cloud.upload_file(local_path, remote_path, content_type: "text/csv") do
      {:ok, "s3://" <> _} = result ->
        File.rm(local_path)
        result
        
      _ ->
        {:ok, local_path}
    end
  end

  @doc """
  Generate PDF export for a research session.
  """
  def generate_pdf(session_id) do
    session = Research.get_session!(session_id)
    
    # Load all analysis results
    results = Analysis.list_results(session_id)
    
    # Generate HTML content
    html_content = generate_html_report(session, results)
    
    # Save HTML to temp file
    html_path = Path.join(System.tmp_dir!(), "report_#{session_id}.html")
    File.write!(html_path, html_content)
    
    # Convert to PDF using ChromicPDF
    pdf_path = Path.join(System.tmp_dir!(), "report_#{session_id}.pdf")
    
    case ChromicPDF.print_to_pdf({:file, html_path}, output: pdf_path) do
      :ok ->
        # Upload to cloud
        remote_path = "exports/#{session.user_id}/report_#{session_id}.pdf"
        case Cloud.upload_file(pdf_path, remote_path, content_type: "application/pdf") do
          {:ok, "s3://" <> _} = result ->
            File.rm(html_path)
            File.rm(pdf_path)
            result
            
          _ ->
            File.rm(html_path)
            {:ok, pdf_path}
        end
        
      {:error, error} ->
        File.rm(html_path)
        {:error, error}
    end
  end

  @doc """
  Generate HTML export for a research session.
  """
  def generate_html(session_id) do
    session = Research.get_session!(session_id)
    results = Analysis.list_results(session_id)
    
    html_content = generate_html_report(session, results)
    
    filename = "report_#{session_id}_#{DateTime.utc_now() |> DateTime.to_unix()}.html"
    local_path = Path.join(System.tmp_dir!(), filename)
    File.write!(local_path, html_content)
    
    # Upload to cloud
    remote_path = "exports/#{session.user_id}/#{filename}"
    case Cloud.upload_file(local_path, remote_path, content_type: "text/html") do
      {:ok, "s3://" <> _} = result ->
        File.rm(local_path)
        result
        
      _ ->
        {:ok, local_path}
    end
  end

  # Private functions
  defp generate_html_report(session, results) do
    sentiment = Enum.find(results, &(&1.analysis_type == "sentiment"))
    funnel = Enum.find(results, &(&1.analysis_type == "funnel"))
    red_flags = Enum.find(results, &(&1.analysis_type == "red_flags"))
    competitors = Enum.find(results, &(&1.analysis_type == "competitors"))
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Research Report - #{session.company.name}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 1200px; margin: 0 auto; padding: 20px; }
        h1 { color: #1f2937; border-bottom: 2px solid #4f46e5; padding-bottom: 10px; }
        h2 { color: #374151; margin-top: 30px; }
        .summary { background: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 2em; font-weight: bold; color: #4f46e5; }
        .metric-label { color: #6b7280; }
        .red-flag { background: #fef2f2; border-left: 4px solid #ef4444; padding: 10px; margin: 10px 0; }
        .recommendation { background: #fffbeb; border-left: 4px solid #f59e0b; padding: 10px; margin: 10px 0; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #e5e7eb; }
        th { background: #f9fafb; font-weight: 600; }
      </style>
    </head>
    <body>
      <h1>HR Brand Research Report</h1>
      <p><strong>Company:</strong> #{session.company.name}</p>
      <p><strong>Industry:</strong> #{session.company.industry}</p>
      <p><strong>Report Date:</strong> #{DateTime.utc_now() |> Calendar.strftime("%B %d, %Y")}</p>
      
      <div class="summary">
        <h2>Executive Summary</h2>
        #{render_sentiment_summary(sentiment)}
        #{render_red_flags_summary(red_flags)}
      </div>
      
      <h2>Detailed Analysis</h2>
      #{render_hiring_funnel(funnel)}
      #{render_competitors(competitors)}
      
      <h2>Recommendations</h2>
      #{render_recommendations(red_flags, funnel)}
    </body>
    </html>
    """
  end

  defp render_sentiment_summary(nil), do: ""
  defp render_sentiment_summary(result) do
    overall = result.results["overall"] || %{}
    percentages = overall["average_percentages"] || %{}
    
    """
    <div class="metric">
      <div class="metric-value">#{Float.round(percentages["positive"] || 0, 1)}%</div>
      <div class="metric-label">Positive Sentiment</div>
    </div>
    <div class="metric">
      <div class="metric-value">#{Float.round(percentages["neutral"] || 0, 1)}%</div>
      <div class="metric-label">Neutral</div>
    </div>
    <div class="metric">
      <div class="metric-value">#{Float.round(percentages["negative"] || 0, 1)}%</div>
      <div class="metric-label">Negative</div>
    </div>
    """
  end

  defp render_red_flags_summary(nil), do: ""
  defp render_red_flags_summary(result) do
    flags = result.results["flags"] || []
    count = length(flags)
    
    if count > 0 do
      """
      <div style="margin-top: 20px;">
        <strong>Red Flags Detected: #{count}</strong>
        <ul>
          #{Enum.map(flags, fn flag -> "<li>#{flag["flag_name"]} (#{flag["severity"]})</li>" end) |> Enum.join()}
        </ul>
      </div>
      """
    else
      "<p><strong>No significant red flags detected</strong></p>"
    end
  end

  defp render_hiring_funnel(nil), do: ""
  defp render_hiring_funnel(result) do
    job = result.results["job_descriptions"] || %{}
    interview = result.results["interview_experience"] || %{}
    
    """
    <h3>Hiring Funnel Analysis</h3>
    <table>
      <tr>
        <th>Aspect</th>
        <th>Score</th>
        <th>Details</th>
      </tr>
      <tr>
        <td>Job Descriptions</td>
        <td>#{job["score"] || "N/A"}</td>
        <td>#{length(job["strengths"] || [])} strengths, #{length(job["issues"] || [])} issues</td>
      </tr>
      <tr>
        <td>Interview Experience</td>
        <td>#{interview["score"] || "N/A"}</td>
        <td>Avg duration: #{interview["avg_duration_days"] || "N/A"} days</td>
      </tr>
    </table>
    """
  end

  defp render_competitors(nil), do: ""
  defp render_competitors(result) do
    position = result.results["market_position"] || "Unknown"
    
    """
    <h3>Competitor Analysis</h3>
    <p><strong>Market Position:</strong> #{position}</p>
    """
  end

  defp render_recommendations(red_flags, funnel) do
    recs = []
    recs = recs ++ (red_flags && red_flags.results["recommendations"] || [])
    recs = recs ++ (funnel && get_in(funnel.results, ["job_descriptions", "recommendations"]) || [])
    
    if length(recs) > 0 do
      Enum.map(recs, fn rec ->
        "<div class='recommendation'>#{rec}</div>"
      end)
      |> Enum.join()
    else
      "<p>No specific recommendations at this time.</p>"
    end
  end
end
