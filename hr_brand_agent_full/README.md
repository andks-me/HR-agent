# HR Brand Research Agent

A comprehensive Elixir/Phoenix application for researching employer brand across LinkedIn, Telegram, and web sources. Features sentiment analysis, hiring funnel evaluation, red flags detection, and competitor comparison.

## Features

### Research Sources
- **LinkedIn**: Company info, job descriptions, reviews (session-based authentication)
- **Telegram**: Bot API for monitoring relevant chats
- **Web**: Glassdoor, Indeed, HeadHunter scraping

### Analysis Modules
- **Sentiment Analysis**: Positive/Neutral/Negative percentage breakdown
- **Hiring Funnel**: Job quality, interview experience, employer image
- **Red Flags**: 7 categories of candidate rejection reasons
- **Competitor Comparison**: Web-3 focused benchmarking

### Dashboard
- Phoenix LiveView real-time interface
- Interactive charts and visualizations
- Export to HTML/PDF/CSV
- Cloud storage integration (AWS S3)

## Prerequisites

- Elixir 1.17+
- Phoenix 1.7+
- SQLite3
- Chrome/Chromium (for LinkedIn automation)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd hr_brand_agent
```

2. Install dependencies:
```bash
mix deps.get
```

3. Setup the database:
```bash
mix ecto.setup
```

4. Install JavaScript dependencies:
```bash
cd assets && npm install && cd ..
```

5. Copy environment variables:
```bash
cp .env.example .env
# Edit .env with your credentials
```

6. Start the server:
```bash
mix phx.server
```

Access the dashboard at http://localhost:4000

## Configuration

### LinkedIn Authentication
Add to `.env`:
```
LINKEDIN_EMAIL=your-email@example.com
LINKEDIN_PASSWORD=your-password
```

### Telegram Bot
1. Message @BotFather on Telegram
2. Create a new bot with `/newbot`
3. Copy the token to `.env`:
```
TELEGRAM_BOT_TOKEN=your-bot-token
```

### OpenAI API (Optional)
```
OPENAI_API_KEY=your-api-key
```

### AWS S3 (Optional)
```
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_REGION=us-east-1
S3_BUCKET=hr-brand-research
```

## Usage

### Web Dashboard
1. Register an account at http://localhost:4000/users/register
2. Login and navigate to Dashboard
3. Click "Start New Research"
4. Enter company details and submit
5. View results at http://localhost:4000/research/:id/results

### CLI

Start research:
```bash
mix research --company "Company Name" --website "https://company.com" --industry "web3"
```

With competitors:
```bash
mix research --company "TargetCo" --competitors "Competitor1,Competitor2"
```

Export results:
```bash
# Export as HTML
mix export --session 123 --format html

# Export as PDF
mix export --session 123 --format pdf

# Export as CSV
mix export --session 123 --format csv
```

## Architecture

```
hr_brand_agent/
├── config/               # Configuration files
├── lib/
│   ├── hr_brand_agent/
│   │   ├── accounts/     # User authentication
│   │   ├── research/     # Research context (companies, sessions, data)
│   │   ├── analysis/     # Analysis modules (sentiment, funnel, red flags)
│   │   ├── integrations/ # LinkedIn, Telegram, Web scrapers
│   │   ├── core/         # Orchestrator
│   │   ├── exports/      # Export generators
│   │   └── storage/      # Cloud storage
│   └── hr_brand_agent_web/  # Phoenix web interface
│       ├── live/         # LiveView modules
│       └── components/   # Reusable components
├── priv/
│   └── repo/migrations/  # Database migrations
└── scripts/              # Utility scripts
```

## Database Schema

### Companies
- name, website, industry, linkedin_url

### Research Sessions
- company_id, user_id, status, data_sources

### LinkedIn Data
- session_id, data_type, content, sentiment_score

### Telegram Data
- session_id, chat_name, message_text, sentiment_score

### Web Data
- session_id, source, content, rating, sentiment_score

### Analysis Results
- session_id, analysis_type, results (JSON)

### Red Flags
- session_id, flag_id, flag_name, severity, frequency

### Competitors
- session_id, name, comparison_data

## API Documentation

### Research Context

```elixir
# Create company
HrBrandAgent.Research.create_company(%{name: "Company", website: "https://..."})

# Start research session
HrBrandAgent.Research.create_session(%{company_id: id, user_id: id})

# Get session with all data
HrBrandAgent.Research.get_session!(id)
```

### Analysis Context

```elixir
# Run sentiment analysis
HrBrandAgent.Analysis.Sentiment.analyze_session(session_id)

# Run hiring funnel analysis
HrBrandAgent.Analysis.HiringFunnel.analyze(session_id)

# Run red flags detection
HrBrandAgent.Analysis.RedFlags.analyze(session_id)

# Get results
HrBrandAgent.Analysis.list_results(session_id)
```

## Testing

Run tests:
```bash
mix test
```

Run with coverage:
```bash
mix coveralls
```

## Development

### Code Quality

Check code style:
```bash
mix credo
```

Type checking:
```bash
mix dialyzer
```

### Adding New Analysis Modules

1. Create module in `lib/hr_brand_agent/analysis/`
2. Implement `analyze(session_id)` function
3. Save results via `HrBrandAgent.Analysis.upsert_result/3`
4. Add UI components in `lib/hr_brand_agent_web/live/`

### Adding New Integrations

1. Create module in `lib/hr_brand_agent/integrations/`
2. Implement data collection functions
3. Call from `HrBrandAgent.Core.Orchestrator`

## Deployment

### Production Build

```bash
# Set production environment
export MIX_ENV=prod

# Compile
mix compile

# Build assets
mix assets.deploy

# Create release
mix release
```

### Docker

```dockerfile
# Dockerfile
FROM elixir:1.17-alpine

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY . .
RUN mix compile

CMD ["mix", "phx.server"]
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details

## Support

For issues and questions, please open a GitHub issue.

## Acknowledgments

- Built with Elixir and Phoenix
- Sentiment analysis powered by Veritaserum
- Telegram integration via Telegex
- Web scraping with Crawly and Floki
