import Config

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /data/hr_brand_prod.db
      """

  config :hr_brand_agent, HrBrandAgent.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
    journal_mode: :wal,
    busy_timeout: 5000

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :hr_brand_agent, HrBrandAgentWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Configure mailer
  config :hr_brand_agent, HrBrandAgent.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: System.get_env("SMTP_HOST"),
    username: System.get_env("SMTP_USER"),
    password: System.get_env("SMTP_PASSWORD"),
    ssl: true,
    tls: :always,
    auth: :always,
    port: 587

  # Cloud Storage Configuration
  config :ex_aws,
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
    region: System.get_env("AWS_REGION", "us-east-1")

  config :ex_aws, :s3,
    bucket: System.get_env("S3_BUCKET", "hr-brand-research")
end
