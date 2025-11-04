defmodule TriviaBuzzer.Repo.Migrations.AddForeignKeys do
  use Ecto.Migration

  def change do
    # SQLite doesn't support ALTER COLUMN to add foreign keys
    # Foreign keys in SQLite must be defined at table creation time
    # This migration is a no-op for SQLite - the foreign key relationship
    # is maintained at the application level via Ecto associations
    adapter = repo().__adapter__()
    
    unless adapter == Ecto.Adapters.SQLite3 do
      alter table(:games) do
        modify :winner_id, references(:players, on_delete: :nilify_all)
      end
    end
  end
end
