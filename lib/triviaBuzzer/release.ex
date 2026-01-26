defmodule TriviaBuzzer.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :trivia_buzzer

  def migrate do
    load_app()

    results = for repo <- repos() do
      # Get database path BEFORE opening connection to avoid WAL lock issues
      database_path = 
        case Application.get_env(:trivia_buzzer, TriviaBuzzer.Repo) do
          nil -> "/data/trivia_buzzer.db"  # Fallback to known production path
          config -> Keyword.get(config, :database, "/data/trivia_buzzer.db")
        end
      
      IO.puts("[Migration] Database path: #{inspect(database_path)}")
      
      # Ensure the directory exists
      database_dir = Path.dirname(database_path)
      case File.mkdir_p(database_dir) do
        :ok -> IO.puts("[Migration] Database directory exists: #{database_dir}")
        {:error, reason} -> 
          IO.puts("[Migration] WARNING: Could not create database directory: #{inspect(reason)}")
      end
      
      # Check if database file exists
      db_exists = File.exists?(database_path)
      IO.puts("[Migration] Database file exists: #{db_exists}")
      
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, fn repo ->
        # First, checkpoint any existing WAL to ensure data is in main database file
        IO.puts("[Migration] Checkpointing WAL if it exists...")
        try do
          Ecto.Adapters.SQL.query!(repo, "PRAGMA wal_checkpoint(TRUNCATE)", [])
          IO.puts("[Migration] WAL checkpointed")
        rescue
          e -> IO.puts("[Migration] Checkpoint failed (may not be in WAL mode): #{inspect(e)}")
        end
        
        # Disable WAL mode to avoid visibility issues between migration and app connections
        IO.puts("[Migration] Setting journal_mode to DELETE")
        try do
          result = Ecto.Adapters.SQL.query!(repo, "PRAGMA journal_mode = DELETE", [])
          IO.puts("[Migration] Journal mode result: #{inspect(result)}")
        rescue
          e -> IO.puts("[Migration] Failed to set journal_mode: #{inspect(e)}")
        end
        
        # Run migrations
        IO.puts("[Migration] Running migrations...")
        migrations_path = Application.app_dir(:trivia_buzzer, "priv/repo/migrations")
        IO.puts("[Migration] Migrations path: #{inspect(migrations_path)}")
        IO.puts("[Migration] Migrations path exists: #{File.exists?(migrations_path)}")
        
        try do
          result = Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: :info)
          IO.puts("[Migration] Migrator.run result: #{inspect(result)}")
        rescue
          e -> 
            IO.puts("[Migration] ERROR running migrations: #{inspect(e)}")
            IO.puts("[Migration] Stacktrace: #{inspect(__STACKTRACE__)}")
            raise e
        end
        IO.puts("[Migration] Migrations completed")
        
        # Verify tables were created - if games table doesn't exist, something went wrong
        try do
          result = Ecto.Adapters.SQL.query!(repo, "SELECT name FROM sqlite_master WHERE type='table';", [])
          tables = Enum.map(result.rows || [], fn row -> 
            name = if is_list(row), do: List.first(row), else: row
            to_string(name || "")
          end)
          IO.puts("[Migration] Tables in database: #{inspect(tables)}")
          
          if not Enum.member?(tables, "games") do
            IO.puts("[Migration] WARNING: 'games' table not found! Migrations may not have run correctly.")
            IO.puts("[Migration] Attempting to drop schema_migrations and re-run migrations...")
            
            # Try to drop schema_migrations to force re-running
            try do
              Ecto.Adapters.SQL.query!(repo, "DROP TABLE IF EXISTS schema_migrations;", [])
              IO.puts("[Migration] Dropped schema_migrations, re-running migrations...")
              Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: :info)
            rescue
              e -> IO.puts("[Migration] Failed to re-run migrations: #{inspect(e)}")
            end
            
            # Verify again
            result2 = Ecto.Adapters.SQL.query!(repo, "SELECT name FROM sqlite_master WHERE type='table';", [])
            tables2 = Enum.map(result2.rows || [], fn row -> 
              name = if is_list(row), do: List.first(row), else: row
              to_string(name || "")
            end)
            IO.puts("[Migration] Tables after re-run: #{inspect(tables2)}")
            
            if not Enum.member?(tables2, "games") do
              raise "CRITICAL: Migrations completed but 'games' table was not created!"
            end
          else
            IO.puts("[Migration] ✓ 'games' table exists - migrations successful")
          end
        rescue
          e -> 
            IO.puts("[Migration] Failed to verify tables: #{inspect(e)}")
            raise "Failed to verify migrations: #{inspect(e)}"
        end
        
        # Ensure final checkpoint and journal mode is DELETE
        try do
          Ecto.Adapters.SQL.query!(repo, "PRAGMA wal_checkpoint(TRUNCATE)", [])
        rescue
          _ -> :ok
        end
      end)
    end
    
    # Return :ok if all migrations succeeded
    if Enum.all?(results, fn result -> match?({:ok, _, _}, result) end) do
      :ok
    else
      {:error, :migration_failed}
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
