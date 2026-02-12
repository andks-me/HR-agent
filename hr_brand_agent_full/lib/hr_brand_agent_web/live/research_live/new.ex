defmodule HrBrandAgentWeb.ResearchLive.New do
  use HrBrandAgentWeb, :live_view

  alias HrBrandAgent.Research
  alias HrBrandAgent.Research.Company
  alias HrBrandAgent.Core.Orchestrator

  @impl true
  def mount(_params, _session, socket) do
    changeset = Research.change_company(%Company{})
    
    socket =
      socket
      |> assign(:page_title, "New Research")
      |> assign(:form, to_form(changeset))
      |> assign(:competitors, [])
      |> assign(:submitting, false)
      |> assign(:error, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="mb-8">
          <.link navigate={~p"/dashboard"} class="text-indigo-600 hover:text-indigo-800 text-sm font-medium">
            ← Back to Dashboard
          </.link>
          <h1 class="mt-4 text-3xl font-bold text-gray-900">Start New Research</h1>
          <p class="mt-2 text-gray-600">Research a company's employer brand across multiple sources</p>
        </div>

        <div class="bg-white rounded-lg shadow p-8">
          <.form
            for={@form}
            id="research-form"
            phx-submit="save"
            phx-change="validate"
            class="space-y-6"
          >
            <%!-- Company Information --%>
            <div>
              <label class="block text-sm font-medium text-gray-700">Company Name</label>
              <.input
                field={@form[:name]}
                type="text"
                placeholder="e.g., OpenSea"
                class="mt-1 block w-full"
                required
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">Website</label>
              <.input
                field={@form[:website]}
                type="url"
                placeholder="https://company.com"
                class="mt-1 block w-full"
              />
              <p class="mt-1 text-sm text-gray-500">Optional, but helps with research accuracy</p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">Industry</label>
              <.input
                field={@form[:industry]}
                type="select"
                options={[
                  {"Web3 / Blockchain", "web3"},
                  {"DeFi", "defi"},
                  {"NFT", "nft"},
                  {"Crypto Exchange", "exchange"},
                  {"Infrastructure", "infrastructure"},
                  {"Other", "other"}
                ]}
                class="mt-1 block w-full"
              />
            </div>

            <%!-- Research Options --%>
            <div class="border-t pt-6">
              <h3 class="text-lg font-medium text-gray-900 mb-4">Research Sources</h3>
              <div class="space-y-3">
                <label class="flex items-center">
                  <input type="checkbox" checked class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" />
                  <span class="ml-2 text-sm text-gray-700">LinkedIn (company info, jobs, reviews)</span>
                </label>
                <label class="flex items-center">
                  <input type="checkbox" checked class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" />
                  <span class="ml-2 text-sm text-gray-700">Web Reviews (Glassdoor, Indeed, HeadHunter)</span>
                </label>
                <label class="flex items-center">
                  <input type="checkbox" class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" />
                  <span class="ml-2 text-sm text-gray-700">Telegram Chats (requires bot setup)</span>
                </label>
              </div>
            </div>

            <%!-- Competitors --%>
            <div class="border-t pt-6">
              <h3 class="text-lg font-medium text-gray-900 mb-4">Competitor Comparison</h3>
              <p class="text-sm text-gray-600 mb-4">Add competitors to compare against (optional)</p>
              
              <div id="competitors" class="space-y-2">
                <%= for {competitor, idx} <- Enum.with_index(@competitors) do %>
                  <div class="flex gap-2">
                    <input
                      type="text"
                      name="competitors[]"
                      value={competitor}
                      placeholder="Competitor name"
                      class="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    />
                    <button
                      type="button"
                      phx-click="remove_competitor"
                      phx-value-idx={idx}
                      class="px-3 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                    >
                      Remove
                    </button>
                  </div>
                <% end %>
              </div>
              
              <button
                type="button"
                phx-click="add_competitor"
                class="mt-2 text-sm text-indigo-600 hover:text-indigo-800 font-medium"
              >
                + Add Competitor
              </button>
            </div>

            <%!-- Error Message --%>
            <%= if @error do %>
              <div class="bg-red-50 border border-red-200 rounded-md p-4">
                <p class="text-sm text-red-800"><%= @error %></p>
              </div>
            <% end %>

            <%!-- Submit Button --%>
            <div class="border-t pt-6 flex justify-end space-x-3">
              <.link
                navigate={~p"/dashboard"}
                class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 font-medium"
              >
                Cancel
              </.link>
              <button
                type="submit"
                disabled={@submitting}
                class={"px-4 py-2 border border-transparent rounded-md text-white font-medium #{if @submitting, do: "bg-indigo-400 cursor-not-allowed", else: "bg-indigo-600 hover:bg-indigo-700"}"}
              >
                <%= if @submitting, do: "Starting Research...", else: "Start Research" %>
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"company" => company_params}, socket) do
    changeset =
      %Company{}
      |> Research.change_company(company_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"company" => company_params}, socket) do
    socket = assign(socket, :submitting, true)
    
    # Check if company exists
    company = Research.get_company_by_name(company_params["name"])
    
    company_result = 
      if company do
        {:ok, company}
      else
        Research.create_company(company_params)
      end
    
    case company_result do
      {:ok, company} ->
        # Start research session
        user_id = socket.assigns.current_user.id
        
        session_attrs = %{
          company_id: company.id,
          user_id: user_id,
          status: "in_progress",
          data_sources: ["linkedin", "web"],
          started_at: DateTime.utc_now()
        }
        
        case Research.create_session(session_attrs) do
          {:ok, session} ->
            # Start research asynchronously
            Task.start(fn ->
              Orchestrator.start_research(session.id, company, socket.assigns.competitors)
            end)
            
            Phoenix.PubSub.broadcast(
              HrBrandAgent.PubSub,
              "dashboard:updates",
              {:new_research, session}
            )
            
            {:noreply, 
             socket
             |> put_flash(:info, "Research started for #{company.name}")
             |> push_navigate(to: ~p"/research/#{session.id}")}
            
          {:error, changeset} ->
            {:noreply, 
             socket
             |> assign(:submitting, false)
             |> assign(:error, "Failed to create research session")}
        end
        
      {:error, changeset} ->
        {:noreply, 
         socket
         |> assign(:submitting, false)
         |> assign(:form, to_form(changeset))
         |> assign(:error, "Please check the form for errors")}
    end
  end

  @impl true
  def handle_event("add_competitor", _params, socket) do
    {:noreply, assign(socket, :competitors, socket.assigns.competitors ++ [""])}
  end

  @impl true
  def handle_event("remove_competitor", %{"idx" => idx}, socket) do
    idx = String.to_integer(idx)
    competitors = List.delete_at(socket.assigns.competitors, idx)
    {:noreply, assign(socket, :competitors, competitors)}
  end
end
