import Config

config :hr_brand_agent,
  ecto_repos: [HrBrandAgent.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :hr_brand_agent, HrBrandAgentWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HrBrandAgentWeb.ErrorHTML, json: HrBrandAgentWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HrBrandAgent.PubSub,
  live_view: [signing_salt: "W7xJz9Qy8K5LmNp2"]

# Configures the mailer
config :hr_brand_agent, HrBrandAgent.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Nx Configuration for ML
config :nx, default_backend: Nx.BinaryBackend

# Application-specific configuration
config :hr_brand_agent, :research,
  sources: [:linkedin, :telegram, :web],
  sentiment_threshold: 0.5,
  max_competitors: 5,
  web3_keywords: [
    "blockchain", "crypto", "web3", "defi", "nft",
    "ethereum", "bitcoin", "solidity", "smart contract", "dao"
  ]

config :hr_brand_agent, :telegram,
  bot_token: System.get_env("TELEGRAM_BOT_TOKEN")

config :hr_brand_agent, :linkedin,
  email: System.get_env("LINKEDIN_EMAIL"),
  password: System.get_env("LINKEDIN_PASSWORD")

config :hr_brand_agent, :openai,
  api_key: System.get_env("OPENAI_API_KEY"),
  base_url: System.get_env("OPENAI_BASE_URL", "https://api.openai.com/v1"),
  model: System.get_env("OPENAI_MODEL", "gpt-3.5-turbo")

# Import environment specific config
import_config "#{config_env()}.exs"
