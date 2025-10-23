defmodule TriviaBuzzer.Teams.TeamMembership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "team_memberships" do
    belongs_to :player, TriviaBuzzer.Players.Player
    belongs_to :team, TriviaBuzzer.Teams.Team

    timestamps()
  end

  @doc false
  def changeset(team_membership, attrs) do
    team_membership
    |> cast(attrs, [:player_id, :team_id])
    |> validate_required([:player_id, :team_id])
    |> unique_constraint(:player_id)
  end
end
