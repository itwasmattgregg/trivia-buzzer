# Fly.io Deployment Guide

## Issues Fixed

### 1. Database Configuration
- ✅ **Fixed**: Uncommented database URL configuration in `config/runtime.exs`
- ✅ **Fixed**: Added proper SSL configuration for production database
- ✅ **Fixed**: Updated Release module to handle migrations properly

### 2. Port Configuration  
- ✅ **Fixed**: Added `PHX_SERVER=true` environment variable
- ✅ **Fixed**: App now listens on `0.0.0.0:8080` as required by Fly.io
- ✅ **Fixed**: Added proper health check endpoint

### 3. Application Stability
- ✅ **Fixed**: Added proper database migration handling
- ✅ **Fixed**: Added health check endpoint at `/health`
- ✅ **Fixed**: Improved error handling in Release module

## Deployment Steps

### 1. Set Environment Variables
```bash
# Generate a secret key
mix phx.gen.secret

# Set the secret key (replace with your generated key)
fly secrets set SECRET_KEY_BASE="your_secret_key_here"

# Set database URL (Fly.io will provide this)
fly secrets set DATABASE_URL="your_database_url_here"
```

### 2. Deploy the Application
```bash
# Deploy to Fly.io
fly deploy

# Check the status
fly status

# View logs
fly logs
```

### 3. Verify Deployment
- Visit your app URL: `https://triviabuzzer.fly.dev`
- Check health endpoint: `https://triviabuzzer.fly.dev/health`
- Test creating a game and joining as a player

## Key Changes Made

### Database Configuration (`config/runtime.exs`)
```elixir
# Before (commented out - caused crashes)
# database_url = System.get_env("DATABASE_URL") || raise "..."

# After (active configuration)
database_url = System.get_env("DATABASE_URL") || raise "..."

config :trivia_buzzer, TriviaBuzzer.Repo,
  ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
```

### Release Module (`lib/triviaBuzzer/release.ex`)
```elixir
# Added proper migration handling
def migrate do
  load_app()
  for repo <- repos() do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
  end
end
```

### Health Check (`lib/trivia_buzzer_web/controllers/health_controller.ex`)
```elixir
def index(conn, _params) do
  json(conn, %{status: "ok", timestamp: DateTime.utc_now()})
end
```

### Fly.io Configuration (`fly.toml`)
```toml
[env]
  PHX_HOST = "triviabuzzer.fly.dev"
  PORT = "8080"
  PHX_SERVER = "true"  # Added this

[[services]]
  http_checks = [
    {
      grace_period = "10s",
      interval = "30s", 
      method = "GET",
      timeout = "5s",
      path = "/health",  # Health check endpoint
      protocol = "http"
    }
  ]
```

## Troubleshooting

### If the app still restarts:
1. **Check logs**: `fly logs`
2. **Verify database connection**: Ensure `DATABASE_URL` is set correctly
3. **Check environment variables**: `fly secrets list`
4. **Test locally**: Run `MIX_ENV=prod mix phx.server` to test production config

### Common Issues:
- **Database not accessible**: Check `DATABASE_URL` format
- **Port binding issues**: Ensure `PHX_SERVER=true` is set
- **Memory issues**: Check Fly.io machine size and resource limits
- **Migration failures**: Check database permissions and connectivity

## Monitoring

- **Health endpoint**: `https://triviabuzzer.fly.dev/health`
- **Fly.io dashboard**: Monitor machine status and logs
- **Database**: Check connection and query performance

The app should now deploy successfully without the restart issues! 🚀
