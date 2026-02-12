defmodule HrBrandAgentWeb.DashboardLive do
  use HrBrandAgentWeb, :live_view

  alias HrBrandAgent.Research
  alias HrBrandAgent.Analysis

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to updates
      Phoenix.PubSub.subscribe(HrBrandAgent.PubSub, "dashboard:updates")
    end

    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:stats, load_stats(user_id))
      |> assign(:recent_research, load_recent_research(user_id))
      |> assign(:active_sessions, load_active_sessions(user_id))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900">Dashboard</h1>
          <p class="mt-2 text-gray-600">Welcome back, <%= @current_user.name || @current_user.email %></p>
        </div>

        <%!-- Stats Cards --%>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <.stat_card
            title="Companies Researched"
            value={@stats.total_companies}
            icon="building-office"
            color="blue"
          />
          <.stat_card
            title="Research Sessions"
            value={@stats.total_sessions}
            icon="magnifying-glass"
            color="green"
          />
          <.stat_card
            title="Avg Sentiment"
            value={@stats.avg_sentiment}%
            icon="face-smile"
            color={sentiment_color(@stats.avg_sentiment)}
          />
          <.stat_card
            title="Red Flags Found"
            value={@stats.total_red_flags}
            icon="exclamation-triangle"
            color={if @stats.total_red_flags > 0, do: "red", else: "gray"}
          />
        </div>

        <%!-- Main Content Grid --%>
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <%!-- Quick Actions --%>
          <div class="lg:col-span-1">
            <div class="bg-white rounded-lg shadow p-6">
              <h2 class="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
              <div class="space-y-3">
                <.link
                  navigate={~p"/research/new"}
                  class="block w-full text-center bg-indigo-600 hover:bg-indigo-700 text-white font-medium py-2 px-4 rounded-lg transition"
                >
                  Start New Research
                </.link>
                <.link
                  navigate={~p"/companies"}
                  class="block w-full text-center bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 font-medium py-2 px-4 rounded-lg transition"
                >
                  View Companies
                </.link>
                <.link
                  navigate={~p"/research"}
                  class="block w-full text-center bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 font-medium py-2 px-4 rounded-lg transition"
                >
                  All Research Sessions
                </.link>
              </div>
            </div>

            <%!-- Active Sessions --%>
            <div class="bg-white rounded-lg shadow p-6 mt-6">
              <h2 class="text-lg font-semibold text-gray-900 mb-4">Active Research</h2>
              <%= if length(@active_sessions) == 0 do %>
                <p class="text-gray-500 text-sm">No active research sessions</p>
              <% else %>
                <div class="space-y-3">
                  <%= for session <- @active_sessions do %>
                    <div class="border-l-4 border-indigo-500 pl-3 py-2">
                      <p class="font-medium text-gray-900"><%= session.company.name %></p>
                      <p class="text-sm text-gray-500">Status: <%= format_status(session.status) %></p>
                      <.link
                        navigate={~p"/research/#{session.id}"}
                        class="text-sm text-indigo-600 hover:text-indigo-800"
                      >
                        View Progress →
                      </.link>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Recent Research --%>
          <div class="lg:col-span-2">
            <div class="bg-white rounded-lg shadow">
              <div class="p-6 border-b border-gray-200">
                <h2 class="text-lg font-semibold text-gray-900">Recent Research</h2>
              </div>
              <%= if length(@recent_research) == 0 do %>
                <div class="p-6 text-center">
                  <p class="text-gray-500 mb-4">No research sessions yet</p>
                  <.link
                    navigate={~p"/research/new"}
                    class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200"
                  >
                    Start your first research
                  </.link>
                </div>
              <% else %>
                <div class="divide-y divide-gray-200">
                  <%= for research <- @recent_research do %>
                    <div class="p-6 hover:bg-gray-50 transition">
                      <div class="flex items-center justify-between">
                        <div>
                          <h3 class="text-lg font-medium text-gray-900">
                            <%= research.company.name %>
                          </h3>
                          <p class="text-sm text-gray-500 mt-1">
                            <%= research.company.industry %> • <%= format_date(research.inserted_at) %>
                          </p>
                        </div>
                        <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{status_badge_class(research.status)}"}>
                          <%= format_status(research.status) %>
                        </span>
                      </div>
                      <div class="mt-4 flex items-center space-x-4">
                        <.link
                          navigate={~p"/research/#{research.id}/results"}
                          class="text-indigo-600 hover:text-indigo-900 text-sm font-medium"
                        >
                          View Results →
                        </.link>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:new_research, _session}, socket) do
    user_id = socket.assigns.current_user.id
    
    {:noreply, 
     socket
     |> assign(:stats, load_stats(user_id))
     |> assign(:recent_research, load_recent_research(user_id))
     |> assign(:active_sessions, load_active_sessions(user_id))}
  end

  # Component helpers
  defp stat_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-6">
      <div class="flex items-center">
        <div class={"flex-shrink-0 rounded-md p-3 bg-#{@color}-100"}>
          <.icon name={"hero-#{@icon}"} class={"w-6 h-6 text-#{@color}-600"} />
        </div>
        <div class="ml-5">
          <p class="text-sm font-medium text-gray-500"><%= @title %></p>
          <p class="text-2xl font-semibold text-gray-900"><%= @value %></p>
        </div>
      </div>
    </div>
    """
  end

  # Private functions
  defp load_stats(user_id) do
    sessions = Research.list_sessions(user_id: user_id)
    companies = Research.list_companies()
    
    avg_sentiment = 
      sessions
      |> Enum.flat_map(fn s -> 
        case Analysis.list_results(s.id) do
          [] -> []
          results -> 
            case Enum.find(results, &(&1.analysis_type == "sentiment")) do
              nil -> []
              result -> [get_in(result.results, [:overall, :average_percentages, :positive]) || 0]
            end
        end
      end)
      |> case do
        [] -> 0
        scores -> Float.round(Enum.sum(scores) / length(scores), 1)
      end
    
    total_red_flags =
      sessions
      |> Enum.map(fn s -> length(Analysis.list_red_flags(s.id)) end)
      |> Enum.sum()

    %{
      total_companies: length(companies),
      total_sessions: length(sessions),
      avg_sentiment: avg_sentiment,
      total_red_flags: total_red_flags
    }
  end

  defp load_recent_research(user_id) do
    Research.list_sessions(user_id: user_id, limit: 5)
  end

  defp load_active_sessions(user_id) do
    Research.list_sessions(user_id: user_id, status: "in_progress")
  end

  defp format_status("pending"), do: "Pending"
  defp format_status("in_progress"), do: "In Progress"
  defp format_status("completed"), do: "Completed"
  defp format_status("failed"), do: "Failed"
  defp format_status(status), do: String.capitalize(status)

  defp status_badge_class("completed"), do: "bg-green-100 text-green-800"
  defp status_badge_class("in_progress"), do: "bg-blue-100 text-blue-800"
  defp status_badge_class("pending"), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_class("failed"), do: "bg-red-100 text-red-800"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-800"

  defp sentiment_color(score) when score >= 70, do: "green"
  defp sentiment_color(score) when score >= 40, do: "yellow"
  defp sentiment_color(_), do: "red"

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end
end
