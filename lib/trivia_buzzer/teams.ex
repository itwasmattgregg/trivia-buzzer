defmodule TriviaBuzzer.Teams do
  @moduledoc """
  The Teams context.
  """

  import Ecto.Query, warn: false
  alias TriviaBuzzer.Repo
  alias TriviaBuzzer.Teams.{Team, TeamMembership}

  @doc """
  Returns the list of teams for a game.
  """
  def list_teams_for_game(game_id) do
    from(t in Team, 
      where: t.game_id == ^game_id,
      preload: [:players]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single team.
  """
  def get_team!(id), do: Repo.get!(Team, id)

  @doc """
  Gets a single team by ID, returns nil if not found.
  """
  def get_team(id) when is_integer(id), do: Repo.get(Team, id)
  def get_team(id) when is_binary(id) do
    case Integer.parse(id) do
      {int_id, ""} -> get_team(int_id)
      _ -> nil
    end
  end

  @doc """
  Creates a team.
  """
  def create_team(attrs \\ %{}) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a team.
  """
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a team.
  """
  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking team changes.
  """
  def change_team(%Team{} = team, attrs \\ %{}) do
    Team.changeset(team, attrs)
  end

  @doc """
  Gets a player's team membership.
  """
  def get_player_team_membership(player_id) do
    from(tm in TeamMembership, 
      where: tm.player_id == ^player_id,
      preload: [:team]
    )
    |> Repo.one()
  end

  @doc """
  Creates a team membership (player joins a team).
  """
  def create_team_membership(attrs \\ %{}) do
    %TeamMembership{}
    |> TeamMembership.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a team membership (player leaves a team).
  """
  def delete_team_membership(%TeamMembership{} = team_membership) do
    Repo.delete(team_membership)
  end

  @doc """
  Makes a player join a team. If the player is already in a team, they leave that team first.
  """
  def join_team(player_id, team_id) do
    # First, remove player from any existing team
    case get_player_team_membership(player_id) do
      nil -> :ok
      existing_membership -> delete_team_membership(existing_membership)
    end

    # Then create new membership
    create_team_membership(%{player_id: player_id, team_id: team_id})
  end

  @doc """
  Makes a player leave their current team.
  """
  def leave_team(player_id) do
    case get_player_team_membership(player_id) do
      nil -> {:ok, nil}
      membership -> delete_team_membership(membership)
    end
  end

  @doc """
  Gets all players in a team.
  """
  def get_team_players(team_id) do
    from(p in TriviaBuzzer.Players.Player,
      join: tm in TeamMembership, on: tm.player_id == p.id,
      where: tm.team_id == ^team_id
    )
    |> Repo.all()
  end
end
