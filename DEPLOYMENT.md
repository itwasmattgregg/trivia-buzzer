# Fly.io Deployment Guide

## Overview

This app uses SQLite3 with Fly.io persistent volumes for database storage. This provides a cost-effective solution since all data is automatically cleaned up every 24 hours.

## Database Migration: PostgreSQL → SQLite

The app has been migrated from PostgreSQL to SQLite3 for reduced hosting costs:

- **Development**: SQLite database at `priv/dev.db`
- **Test**: SQLite database at `priv/test*.db`
- **Production**: SQLite database at `/data/trivia_buzzer.db` (on Fly.io volume)

## Deployment Steps

### 1. Create Persistent Volume

SQLite requires persistent storage. Create a volume first:

```bash
# Create a 1GB volume for the SQLite database
fly volumes create trivia_buzzer_data --size 1
```

### 2. Set Environment Variables

```bash
# Generate a secret key
mix phx.gen.secret

# Set the secret key (replace with your generated key)
fly secrets set SECRET_KEY_BASE="your_secret_key_here"
```

**Note**: Unlike PostgreSQL deployments, no `DATABASE_URL` is needed since SQLite uses a local file.

### 3. Deploy the Application

```bash
# Deploy to Fly.io
fly deploy

# Check the status
fly status

# View logs
fly logs
```

### 4. Verify Deployment

- Visit your app URL: `https://triviabuzzer.fly.dev`
- Check health endpoint: `https://triviabuzzer.fly.dev/health`
- Test creating a game and joining as a player

## Key Configuration

### Database Configuration (`config/runtime.exs`)

```elixir
if config_env() == :prod do
  # Configure SQLite database path
  # Uses /data directory which will be mounted as a Fly.io volume
  config :trivia_buzzer, TriviaBuzzer.Repo,
    database: "/data/trivia_buzzer.db",
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
end
```

### Fly.io Configuration (`fly.toml`)

```toml
[mounts]
  source = "trivia_buzzer_data"
  destination = "/data"

[env]
  PHX_HOST = "triviabuzzer.fly.dev"
  PORT = "8080"
  PHX_SERVER = "true"

[deploy]
  release_command = "/app/bin/migrate"
```

## Cleanup Scheduler

The app includes a cleanup scheduler that runs every hour to delete games older than 24 hours. This ensures the SQLite database stays manageable and keeps hosting costs low:

- Cleanup runs via `TriviaBuzzer.Scheduler.CleanupScheduler`
- Deletes old games and all associated players, teams, and team memberships
- Foreign keys ensure proper cascade deletion

## Troubleshooting

### If the app fails to start:

1. **Check logs**: `fly logs`
2. **Verify volume is attached**: `fly volumes list`
3. **Check environment variables**: `fly secrets list`
4. **Test locally**: Run `MIX_ENV=prod mix phx.server` to test production config

### Common Issues:

- **Database file permissions**: Ensure the `/data` directory is writable
- **Volume not mounted**: Verify volume exists with `fly volumes list`
- **Port binding issues**: Ensure `PHX_SERVER=true` is set
- **Migration failures**: Check logs for SQLite-specific errors

### Viewing Database Content

```bash
# SSH into the Fly.io machine
fly ssh console

# Access the SQLite database
sqlite3 /data/trivia_buzzer.db

# Run SQL commands
SELECT * FROM games;
.quit
```

## Monitoring

- **Health endpoint**: `https://triviabuzzer.fly.dev/health`
- **Fly.io dashboard**: Monitor machine status and logs
- **Volume usage**: Check volume size with `fly volumes list`
- **Database stats**: The cleanup scheduler logs game statistics

## Backup Considerations

Since data is cleaned up after 24 hours, backups are typically not necessary. However, if you need to backup the SQLite database:

```bash
# SSH into machine and copy database
fly ssh console
cp /data/trivia_buzzer.db /data/backup.db
exit

# Or use fly volumes to create a snapshot
# (if supported by Fly.io)
```

## Advantages of SQLite

- **Zero-cost database**: No managed database service fees
- **Simpler deployment**: No external database connections
- **Perfect fit**: Single-instance writes, automatic cleanup, moderate traffic
- **Persistent storage**: Fly.io volumes provide durability across restarts
- **Easy debugging**: Single-file database is easy to inspect and understand

The app should now deploy successfully with reduced hosting costs! 🚀