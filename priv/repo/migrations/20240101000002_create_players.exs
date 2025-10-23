defmodule TriviaBuzzer.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :string, null: false
      add :game_id, references(:games, on_delete: :delete_all), null: false
      add :inserted_at, :naive_datetime, null: false
      add :updated_at, :naive_datetime, null: false
    end

    create index(:players, [:game_id])
  end
end
