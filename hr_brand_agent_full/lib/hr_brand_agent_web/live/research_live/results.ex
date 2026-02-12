defmodule HrBrandAgentWeb.ResearchLive.Results do
  use HrBrandAgentWeb, :live_view

  alias HrBrandAgent.Research
  alias HrBrandAgent.Analysis

  @impl true
  def mount(%{"id" => session_id}, _session, socket) do
    session = Research.get_session!(session_id)
    
    # Load all analysis results
    sentiment_result = get_analysis_result(session_id, "sentiment")
    funnel_result = get_analysis_result(session_id, "funnel")
    red_flags_result = get_analysis_result(session_id, "red_flags")
    competitors_result = get_analysis_result(session_id, "competitors")
    
    socket =
      socket
      |> assign(:page_title, "Research Results - #{session.company.name}")
      |> assign(:session, session)
      |> assign(:company, session.company)
      |> assign(:sentiment, sentiment_result)
      |> assign(:funnel, funnel_result)
      |> assign(:red_flags, red_flags_result)
      |> assign(:competitors, competitors_result)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 pb-12">
      <%!-- Header --%>
      <div class="bg-white shadow">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div class="flex items-center justify-between">
            <div>
              <.link navigate={~p"/dashboard"} class="text-indigo-600 hover:text-indigo-800 text-sm font-medium">
                ← Back to Dashboard
              </.link>
              <h1 class="mt-2 text-3xl font-bold text-gray-900"><%= @company.name %></h1>
              <p class="mt-1 text-gray-600"><%= @company.industry %> • Research completed <%= format_date(@session.completed_at || @session.inserted_at) %></p>
            </div>
            <div class="flex space-x-3">
              <button
                phx-click="export_csv"
                class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
              >
                Export CSV
              </button>
              <button
                phx-click="export_pdf"
                class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
              >
                Export PDF
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Executive Summary --%>
        <div class="bg-white rounded-lg shadow mb-8">
          <div class="p-6 border-b border-gray-200">
            <h2 class="text-xl font-semibold text-gray-900">Executive Summary</h2>
          </div>
          <div class="p-6">
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
              <div class="text-center">
                <div class={"text-3xl font-bold #{sentiment_color_class(@sentiment[:overall][:average_percentages][:positive])}"}>
                  <%= format_percentage(@sentiment[:overall][:average_percentages][:positive]) %>
                </div>
                <div class="text-sm text-gray-600 mt-1">Positive Sentiment</div>
              </div>
              <div class="text-center">
                <div class="text-3xl font-bold text-gray-900">
                  <%= format_score(@funnel[:overall_score]) %>
                </div>
                <div class="text-sm text-gray-600 mt-1">Hiring Funnel Score</div>
              </div>
              <div class="text-center">
                <div class={"text-3xl font-bold #{if (@red_flags[:total_flags_detected] || 0) > 0, do: "text-red-600", else: "text-green-600"}"}>
                  <%= @red_flags[:total_flags_detected] || 0 %>
                </div>
                <div class="text-sm text-gray-600 mt-1">Red Flags</div>
              </div>
              <div class="text-center">
                <div class="text-3xl font-bold text-gray-900">
                  <%= format_score(@competitors[:market_position]) %>
                </div>
                <div class="text-sm text-gray-600 mt-1">Market Position</div>
              </div>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <%!-- Sentiment Analysis --%>
          <div class="bg-white rounded-lg shadow">
            <div class="p-6 border-b border-gray-200">
              <h2 class="text-xl font-semibold text-gray-900">Sentiment Analysis</h2>
            </div>
            <div class="p-6">
              <%= if @sentiment do %>
                <div class="space-y-4">
                  <% overall = @sentiment[:overall][:average_percentages] || %{} %>
                  <.sentiment_bar label="Positive" percentage={overall[:positive] || 0} color="green" />
                  <.sentiment_bar label="Neutral" percentage={overall[:neutral] || 0} color="gray" />
                  <.sentiment_bar label="Negative" percentage={overall[:negative] || 0} color="red" />
                </div>
                <div class="mt-6 pt-6 border-t">
                  <h4 class="text-sm font-medium text-gray-700 mb-2">Data Sources</h4>
                  <div class="grid grid-cols-3 gap-4 text-sm">
                    <div class="text-center p-3 bg-gray-50 rounded">
                      <div class="font-medium"><%= get_in(@sentiment, [:by_source, :linkedin, :total_analyzed]) || 0 %></div>
                      <div class="text-gray-500">LinkedIn</div>
                    </div>
                    <div class="text-center p-3 bg-gray-50 rounded">
                      <div class="font-medium"><%= get_in(@sentiment, [:by_source, :telegram, :total_analyzed]) || 0 %></div>
                      <div class="text-gray-500">Telegram</div>
                    </div>
                    <div class="text-center p-3 bg-gray-50 rounded">
                      <div class="font-medium"><%= get_in(@sentiment, [:by_source, :web, :total_analyzed]) || 0 %></div>
                      <div class="text-gray-500">Web Reviews</div>
                    </div>
                  </div>
                </div>
              <% else %>
                <p class="text-gray-500">Sentiment analysis not yet complete</p>
              <% end %>
            </div>
          </div>

          <%!-- Red Flags --%>
          <div class="bg-white rounded-lg shadow">
            <div class="p-6 border-b border-gray-200">
              <h2 class="text-xl font-semibold text-gray-900">Red Flags Detected</h2>
            </div>
            <div class="p-6">
              <%= if @red_flags && length(@red_flags[:flags] || []) > 0 do %>
                <div class="space-y-4">
                  <%= for flag <- (@red_flags[:flags] || []) do %>
                    <div class="flex items-start space-x-3 p-4 rounded-lg <%= severity_bg_class(flag.severity) %>">
                      <div class="flex-shrink-0">
                        <.icon name="hero-exclamation-triangle" class={"w-5 h-5 #{severity_text_class(flag.severity)}"} />
                      </div>
                      <div class="flex-1">
                        <h4 class="font-medium <%= severity_text_class(flag.severity) %>"><%= flag.flag_name %></h4>
                        <p class="text-sm text-gray-600 mt-1"><%= flag.description %></p>
                        <p class="text-xs text-gray-500 mt-2">Mentioned <%= flag.frequency %> times</p>
                      </div>
                      <span class={"inline-flex items-center px-2 py-1 rounded text-xs font-medium #{severity_badge_class(flag.severity)}"}>
                        <%= String.capitalize(flag.severity) %>
                      </span>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <div class="text-center py-8">
                  <.icon name="hero-check-circle" class="w-12 h-12 text-green-500 mx-auto" />
                  <p class="mt-2 text-gray-600">No significant red flags detected</p>
                </div>
              <% end %>
            </div>
          </div>

         <%!-- Hiring Funnel --%>
          <div class="bg-white rounded-lg shadow">
            <div class="p-6 border-b border-gray-200">
              <h2 class="text-xl font-semibold text-gray-900">Hiring Funnel Analysis</h2>
            </div>
            <div class="p-6">
              <%= if @funnel do %>
                <div class="space-y-6">
                  <div>
                    <div class="flex justify-between items-center mb-2">
                      <h4 class="font-medium text-gray-900">Job Descriptions</h4>
                      <span class="text-lg font-bold text-indigo-600">
                        <%= format_score(@funnel[:job_descriptions][:score]) %>
                      </span>
                    </div>
                    <div class="text-sm text-gray-600">
                      Clarity: <%= @funnel[:job_descriptions][:clarity_score] || 0 %>% • 
                      Transparency: <%= @funnel[:job_descriptions][:transparency_score] || 0 %>% • 
                      Attractiveness: <%= @funnel[:job_descriptions][:attractiveness_score] || 0 %>%
                    </div>
                  </div>

                  <div>
                    <div class="flex justify-between items-center mb-2">
                      <h4 class="font-medium text-gray-900">Interview Experience</h4>
                      <span class="text-lg font-bold text-indigo-600">
                        <%= format_score(@funnel[:interview_experience][:score]) %>
                      </span>
                    </div>
                    <div class="text-sm text-gray-600">
                      Recruiter: <%= @funnel[:interview_experience][:recruiter_score] || 0 %>% • 
                      Process: <%= @funnel[:interview_experience][:process_score] || 0 %>% • 
                      Communication: <%= @funnel[:interview_experience][:communication_score] || 0 %>%
                    </div>
                    <%= if @funnel[:interview_experience][:avg_duration_days] do %>
                      <p class="text-sm text-gray-500 mt-1">
                        Avg. process duration: <%= @funnel[:interview_experience][:avg_duration_days] %> days
                      </p>
                    <% end %>
                  </div>

                  <div>
                    <div class="flex justify-between items-center mb-2">
                      <h4 class="font-medium text-gray-900">Employer Image</h4>
                      <span class="text-lg font-bold text-indigo-600">
                        <%= format_score(@funnel[:employer_image][:score]) %>
                      </span>
                    </div>
                    <%= if length(@funnel[:employer_image][:attractors] || []) > 0 do %>
                      <div class="flex flex-wrap gap-2 mt-2">
                        <%= for attractor <- @funnel[:employer_image][:attractors] || [] do %>
                          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            <%= attractor %>
                          </span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% else %>
                <p class="text-gray-500">Funnel analysis not yet complete</p>
              <% end %>
            </div>
          </div>


                  <% interview = @funnel[:interview_experience] || %{} %>
                  <div>
                    <div class="flex justify-between items-center mb-2">
                      <h4 class="font-medium text-gray-900">Interview Experience</h4>
                      <span class="text-lg font-bold text-indigo-600"><%= format_score(interview[:score]) %></span>
                    </div>
                    <div class="text-sm text-gray-600">
                      Recruiter: <%= interview[:recruiter_score] || 0 %>% • 
                      Process: <%= interview[:process_score] || 0 %>% • 
                      Communication: <%= interview[:communication_score] || 0 %>%
                    </div>
                    <%= if interview[:avg_duration_days] do %>
                      <p class="text-sm text-gray-500 mt-1">Avg. process duration: <%= interview[:avg_duration_days] %> days</p>
                    <% end %>
                  </div>

                  <% image = @funnel[:employer_image] || %{} %>
                  <div>
                    <div class="flex justify-between items-center mb-2">
                      <h4 class="font-medium text-gray-900">Employer Image</h4>
                      <span class="text-lg font-bold text-indigo-600"><%= format_score(image[:score]) %></span>
                    </div>
                    <%= if length(image[:attractors] || []) > 0 do %>
                      <div class="flex flex-wrap gap-2 mt-2">
                        <%= for attractor <- image[:attractors] || [] do %>
                          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            <%= attractor %>
                          </span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% else %>
                <p class="text-gray-500">Funnel analysis not yet complete</p>
              <% end %>
            </div>
          </div>

          <%!-- Competitor Comparison --%>
          <div class="bg-white rounded-lg shadow">
            <div class="p-6 border-b border-gray-200">
              <h2 class="text-xl font-semibold text-gray-900">Competitor Comparison</h2>
            </div>
            <div class="p-6">
              <%= if @competitors do %>
                <div class="space-y-4">
                  <div class="flex justify-between items-center p-4 bg-indigo-50 rounded-lg">
                    <span class="font-medium text-indigo-900">Market Position</span>
                    <span class="text-lg font-bold text-indigo-600"><%= @competitors[:market_position] || "Unknown" %></span>
                  </div>

                  <%= if length(@competitors[:competitive_advantages] || []) > 0 do %>
                    <div>
                      <h4 class="font-medium text-gray-900 mb-2">Competitive Advantages</h4>
                      <ul class="space-y-1">
                        <%= for adv <- @competitors[:competitive_advantages] || [] do %>
                          <li class="flex items-center text-sm text-gray-600">
                            <.icon name="hero-check" class="w-4 h-4 text-green-500 mr-2" />
                            <%= adv %>
                          </li>
                        <% end %>
                      </ul>
                    </div>
                  <% end %>

                  <%= if length(@competitors[:detailed_comparison] || []) > 0 do %>
                    <div class="mt-4">
                      <h4 class="font-medium text-gray-900 mb-2">Key Competitors</h4>
                      <div class="space-y-2">
                        <%= for comp <- Enum.take(@competitors[:detailed_comparison] || [], 3) do %>
                          <div class="flex justify-between items-center p-3 bg-gray-50 rounded text-sm">
                            <span class="font-medium"><%= comp.name %></span>
                            <span class="text-gray-600">Score: <%= comp.reputation_score || 0 %></span>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <p class="text-gray-500">No competitor analysis available</p>
              <% end %>
            </div>
          </div>
        </div>

        <%!-- Recommendations --%>
        <%= if has_recommendations?(@red_flags, @funnel) do %>
          <div class="mt-8 bg-white rounded-lg shadow">
            <div class="p-6 border-b border-gray-200">
              <h2 class="text-xl font-semibold text-gray-900">Recommendations</h2>
            </div>
            <div class="p-6">
              <div class="space-y-4">
                <%= for rec <- (@red_flags[:recommendations] || []) do %>
                  <div class="flex items-start space-x-3">
                    <.icon name="hero-light-bulb" class="w-5 h-5 text-yellow-500 mt-0.5" />
                    <p class="text-gray-700"><%= rec %></p>
                  </div>
                <% end %>
                <%= for rec <- (@funnel[:job_descriptions][:recommendations] || []) do %>
                  <div class="flex items-start space-x-3">
                    <.icon name="hero-light-bulb" class="w-5 h-5 text-yellow-500 mt-0.5" />
                    <p class="text-gray-700"><%= rec %></p>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Component helpers
  defp sentiment_bar(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between text-sm mb-1">
        <span class="font-medium text-gray-700"><%= @label %></span>
        <span class="text-gray-600"><%= Float.round(@percentage, 1) %>%</span>
      </div>
      <div class="w-full bg-gray-200 rounded-full h-2.5">
        <div class={"bg-#{@color}-600 h-2.5 rounded-full transition-all duration-500"} style={"width: #{@percentage}%"}></div>
      </div>
    </div>
    """
  end

  # Private functions
  defp get_analysis_result(session_id, analysis_type) do
    case Analysis.list_results(session_id) do
      [] -> nil
      results ->
        case Enum.find(results, &(&1.analysis_type == analysis_type)) do
          nil -> nil
          result -> result.results
        end
    end
  end

  defp format_date(nil), do: "N/A"
  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end

  defp format_percentage(nil), do: "0%"
  defp format_percentage(value), do: "#{Float.round(value, 1)}%"

  defp format_score(nil), do: "N/A"
  defp format_score(value) when is_binary(value), do: value
  defp format_score(value), do: "#{value}"

  defp sentiment_color_class(nil), do: "text-gray-600"
  defp sentiment_color_class(score) when score >= 70, do: "text-green-600"
  defp sentiment_color_class(score) when score >= 40, do: "text-yellow-600"
  defp sentiment_color_class(_), do: "text-red-600"

  defp severity_bg_class("high"), do: "bg-red-50"
  defp severity_bg_class("medium"), do: "bg-yellow-50"
  defp severity_bg_class(_), do: "bg-gray-50"

  defp severity_text_class("high"), do: "text-red-800"
  defp severity_text_class("medium"), do: "text-yellow-800"
  defp severity_text_class(_), do: "text-gray-800"

  defp severity_badge_class("high"), do: "bg-red-100 text-red-800"
  defp severity_badge_class("medium"), do: "bg-yellow-100 text-yellow-800"
  defp severity_badge_class(_), do: "bg-gray-100 text-gray-800"

  defp has_recommendations?(red_flags, funnel) do
    length(red_flags[:recommendations] || []) > 0 or
    length(funnel[:job_descriptions][:recommendations] || []) > 0
  end

  @impl true
  def handle_event("export_csv", _params, socket) do
    # Trigger CSV export
    {:noreply, put_flash(socket, :info, "CSV export started. You will receive an email when ready.")}
  end

  @impl true
  def handle_event("export_pdf", _params, socket) do
    # Trigger PDF export
    {:noreply, put_flash(socket, :info, "PDF export started. You will receive an email when ready.")}
  end
end
