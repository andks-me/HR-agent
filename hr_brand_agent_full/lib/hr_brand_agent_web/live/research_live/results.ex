defmodule HrBrandAgentWeb.ResearchLive.Results do
  use HrBrandAgentWeb, :live_view

  alias HrBrandAgent.Research
  alias HrBrandAgent.Analysis

  @impl true
  def mount(%{"id" => session_id}, _session, socket) do
    session = Research.get_session!(session_id)

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
              <p class="mt-1 text-gray-600">
                <%= @company.industry %> •
                Research completed <%= format_date(@session.completed_at || @session.inserted_at) %>
              </p>
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
                      <div cla
