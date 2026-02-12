defmodule HrBrandAgent.Application do
  @moduledoc """
  OTP Application for HrBrandAgent.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      HrBrandAgent.Repo,
      
      # Start the Telemetry supervisor
      HrBrandAgentWeb.Telemetry,
      
      # Start the PubSub system
      {Phoenix.PubSub, name: HrBrandAgent.PubSub},
      
      # Start Finch HTTP client
      {Finch, name: HrBrandAgent.Finch},
      
      # Start Oban for background jobs
      {Oban, Application.fetch_env!(:hr_brand_agent, Oban)},
      
      # Start the Endpoint (http/https)
      HrBrandAgentWeb.Endpoint,
      
      # Start Hound for browser automation
      HrBrandAgent.Integrations.LinkedIn.Browser,
      
      # Start Telegram bot
      HrBrandAgent.Integrations.Telegram.Bot
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HrBrandAgent.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    HrBrandAgentWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
