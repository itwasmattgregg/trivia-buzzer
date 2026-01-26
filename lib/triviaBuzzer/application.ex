defmodule TriviaBuzzer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Ensure SSL is started before database connections
    :ssl.start()
    
    children = [
      # Start the Ecto repository
      TriviaBuzzer.Repo,
      # Start the cleanup scheduler
      TriviaBuzzer.Scheduler.CleanupScheduler,
      # Start the Telemetry supervisor
      TriviaBuzzerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: TriviaBuzzer.PubSub},
      # Start the Endpoint (http/https)
      TriviaBuzzerWeb.Endpoint
      # Start a worker by calling: TriviaBuzzer.Worker.start_link(arg)
      # {TriviaBuzzer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TriviaBuzzer.Supervisor]
    
    result = Supervisor.start_link(children, opts)
    
    # Initialize database connection settings after Repo starts
    # Ensure SQLite uses DELETE journal mode (not WAL) to avoid visibility issues
    # This is especially important in production where migrations run separately
    # Also verify that required tables exist and run migrations if needed
    spawn(fn ->
      Process.sleep(1000) # Give Repo time to fully start and establish connection
      try do
        Ecto.Adapters.SQL.query!(TriviaBuzzer.Repo, "PRAGMA journal_mode = DELETE", [])
        
        # Verify critical tables exist
        case Ecto.Adapters.SQL.query(TriviaBuzzer.Repo, 
          "SELECT name FROM sqlite_master WHERE type='table' AND name='games'", []) do
          {:ok, %{rows: [[_name]]}} ->
            require Logger
            Logger.info("[Database] ✓ 'games' table exists - database is ready")
          _ ->
            # Table doesn't exist - try to run migrations automatically
            require Logger
            Logger.warn("""
            [Database] Table 'games' does not exist! Attempting to run migrations automatically...
            """)
            
            try do
              # Run migrations using the Release module
              TriviaBuzzer.Release.migrate()
              require Logger
              Logger.info("[Database] ✓ Migrations completed successfully")
            rescue
              migration_error ->
                require Logger
                Logger.error("""
                [CRITICAL] Failed to run migrations automatically: #{inspect(migration_error)}
                Please run migrations manually: /app/bin/migrate
                """)
            end
        end
      rescue
        e ->
          require Logger
          Logger.error("Failed to verify database: #{inspect(e)}")
      end
    end)
    
    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TriviaBuzzerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
