defmodule TriviaBuzzer.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    field :game_code, :string
    field :admin_token, :string
    field :state, :string, default: "locked"

    has_many :players, TriviaBuzzer.Players.Player
    has_many :teams, TriviaBuzzer.Teams.Team
    belongs_to :winner, TriviaBuzzer.Players.Player, foreign_key: :winner_id

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :game_code, :admin_token, :state, :winner_id])
    |> validate_required([:name, :game_code, :admin_token])
    |> validate_inclusion(:state, ["locked", "open", "buzzed"])
    |> unique_constraint(:game_code)
    |> unique_constraint(:admin_token)
  end
end
