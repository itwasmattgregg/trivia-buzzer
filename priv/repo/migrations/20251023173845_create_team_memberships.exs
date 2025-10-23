defmodule TriviaBuzzer.Repo.Migrations.CreateTeamMemberships do
  use Ecto.Migration

  def change do
    create table(:team_memberships) do
      add :player_id, references(:players, on_delete: :delete_all), null: false
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :inserted_at, :naive_datetime, null: false
      add :updated_at, :naive_datetime, null: false
    end

    create index(:team_memberships, [:player_id])
    create index(:team_memberships, [:team_id])
    create unique_index(:team_memberships, [:player_id], name: :team_memberships_player_id_unique_index)
  end
end