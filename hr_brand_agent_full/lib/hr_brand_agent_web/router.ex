defmodule HrBrandAgentWeb.Router do
  use HrBrandAgentWeb, :router

  import HrBrandAgentWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HrBrandAgentWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HrBrandAgentWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", HrBrandAgentWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:hr_brand_agent, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HrBrandAgentWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", HrBrandAgentWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{HrBrandAgentWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", HrBrandAgentWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{HrBrandAgentWeb.UserAuth, :ensure_authenticated}] do
      # Dashboard routes
      live "/dashboard", DashboardLive, :index
      live "/companies", CompanyLive.Index, :index
      live "/companies/new", CompanyLive.Index, :new
      live "/companies/:id", CompanyLive.Show, :show
      live "/companies/:id/edit", CompanyLive.Index, :edit
      
      live "/research", ResearchLive.Index, :index
      live "/research/new", ResearchLive.Index, :new
      live "/research/:id", ResearchLive.Show, :show
      live "/research/:id/results", ResearchLive.Results, :results
      
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", HrBrandAgentWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end
end
