defmodule TriviaBuzzer.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :string, null: false
      add :game_code, :string, null: false
      add :admin_token, :string, null: false
      add :state, :string, default: "locked", null: false
      add :winner_id, :id
      add :inserted_at, :naive_datetime, null: false
      add :updated_at, :naive_datetime, null: false
    end

    create unique_index(:games, [:game_code])
    create unique_index(:games, [:admin_token])
  end
end
