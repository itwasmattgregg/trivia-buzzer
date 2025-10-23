defmodule TriviaBuzzer.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    belongs_to :game, TriviaBuzzer.Games.Game
    has_many :team_memberships, TriviaBuzzer.Teams.TeamMembership
    has_many :players, through: [:team_memberships, :player]

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :game_id])
    |> validate_required([:name, :game_id])
    |> validate_length(:name, min: 1, max: 50)
    |> unique_constraint(:name, name: :teams_name_game_id_index)
  end
end
