defmodule HrBrandAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :hr_brand_agent,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {HrBrandAgent.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix & Web
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_live_view, "~> 0.20.0"},
      {:phoenix_html, "~> 4.0"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.5"},
      {:bandit, "~> 1.0"},

      # Database
      {:ecto_sql, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.17"},

      # Authentication
      {:bcrypt_elixir, "~> 3.0"},

      # HTTP & API
      {:finch, "~> 0.18"},
      {:req, "~> 0.4"},
      {:httpoison, "~> 2.0"},

      # Telegram
      # {:telegex, "~> 1.9.0-rc.0"},

      # Web Scraping
      {:hound, "~> 1.1"},
      {:crawly, "~> 0.16"},
      {:floki, "~> 0.35"},

      # Sentiment Analysis (disabled for now)
      # {:veritaserum, "~> 0.2.2"},
      # {:bumblebee, "~> 0.6.0"},
      # {:exla, ">= 0.0.0"},
      # {:nx, "~> 0.9.0"},

      # PDF Export
      {:chromic_pdf, "~> 1.2"},

      # Cloud Storage
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:hackney, "~> 1.18"},

      # Background Jobs
      {:oban, "~> 2.17"},

      # Utilities
      {:dotenvy, "~> 0.8"},
      {:yaml_elixir, "~> 2.9"},
      {:timex, "~> 3.7"},
      {:csv, "~> 3.0"},
      {:number, "~> 1.0"},

      # Telemetry
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},

      # Development
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["cmd --cd assets npm install"],
      "assets.build": ["cmd --cd assets node build.js"],
      "assets.deploy": ["cmd --cd assets node build.js --deploy", "phx.digest"]
    ]
  end
end
