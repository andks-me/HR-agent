import Config

# For development, we disable any cache and enable debugging and code reloading.
config :hr_brand_agent, HrBrandAgentWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev-secret-key-base-for-development-only-do-not-use-in-production",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading
config :hr_brand_agent, HrBrandAgentWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/hr_brand_agent_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Configure SQLite database
config :hr_brand_agent, HrBrandAgent.Repo,
  database: Path.expand("../hr_brand_dev.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  journal_mode: :wal,
  temp_store: :memory,
  cache_size: -64000,
  busy_timeout: 2000
