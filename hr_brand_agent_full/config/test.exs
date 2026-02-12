import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hr_brand_agent, HrBrandAgentWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key-base-for-testing-only",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Configure SQLite database for test
config :hr_brand_agent, HrBrandAgent.Repo,
  database: Path.expand("../hr_brand_test.db", Path.dirname(__ENV__.file)),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2
