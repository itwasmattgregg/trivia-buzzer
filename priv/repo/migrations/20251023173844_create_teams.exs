defmodule TriviaBuzzer.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      add :game_id, references(:games, on_delete: :delete_all), null: false
      add :inserted_at, :naive_datetime, null: false
      add :updated_at, :naive_datetime, null: false
    end

    create index(:teams, [:game_id])
    create unique_index(:teams, [:name, :game_id])
  end
end