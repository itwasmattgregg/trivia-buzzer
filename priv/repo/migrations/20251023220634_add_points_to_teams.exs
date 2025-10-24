defmodule TriviaBuzzer.Repo.Migrations.AddPointsToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :points, :integer, default: 0, null: false
    end
  end
end
