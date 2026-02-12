defmodule HrBrandAgentWeb.UserRegistrationLive do
  use HrBrandAgentWeb, :live_view

  alias HrBrandAgent.Accounts
  alias HrBrandAgent.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Create your account
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            Start researching employer brands
          </p>
        </div>
        <.form
          :let={f}
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log_in?_action=registered"}
          method="post"
          class="mt-8 space-y-6"
        >
          <div class="rounded-md shadow-sm -space-y-px">
            <div>
              <.input
                field={f[:name]}
                type="text"
                label="Full Name"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Full Name"
              />
            </div>
            <div>
              <.input
                field={f[:email]}
                type="email"
                label="Email"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
              />
            </div>
            <div>
              <.input
                field={f[:password]}
                type="password"
                label="Password"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Password (min 12 characters)"
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              phx-disable-with="Creating account..."
              class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Create account
            </button>
          </div>
        </.form>

        <div class="text-center">
          <p class="text-sm text-gray-600">
            Already have an account?
            <.link href={~p"/users/log_in"} class="font-medium text-indigo-600 hover:text-indigo-500">
              Sign in
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user(%User{})
    
    socket =
      socket
      |> assign(:trigger_submit, false)
      |> assign(:form, to_form(changeset))
    
    {:ok, socket}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        changeset = Accounts.change_user(user)
        
        {:noreply,
         socket
         |> assign(:trigger_submit, true)
         |> assign(:form, to_form(changeset))}
      
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(:form, to_form(changeset))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user(%User{}, user_params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end
end
