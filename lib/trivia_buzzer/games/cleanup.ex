defmodule TriviaBuzzer.Games.Cleanup do
  @moduledoc """
  Handles cleanup of old games and related data.
  """

  import Ecto.Query, warn: false
  alias TriviaBuzzer.Repo
  alias TriviaBuzzer.Games.Game
  alias TriviaBuzzer.Players.Player

  @doc """
  Deletes games that were created more than 24 hours ago.
  Also cleans up associated players.
  """
  def cleanup_old_games do
    cutoff_time = DateTime.utc_now() |> DateTime.add(-24, :hour)
    
    # Find games older than 24 hours
    old_games = 
      from(g in Game, 
        where: g.inserted_at < ^cutoff_time,
        select: g.id
      )
      |> Repo.all()

    if length(old_games) > 0 do
      # Delete associated players first (foreign key constraint)
      from(p in Player, where: p.game_id in ^old_games)
      |> Repo.delete_all()

      # Delete the old games
      from(g in Game, where: g.id in ^old_games)
      |> Repo.delete_all()

      IO.puts("Cleaned up #{length(old_games)} old games and their players")
      length(old_games)
    else
      IO.puts("No old games to clean up")
      0
    end
  end

  @doc """
  Gets statistics about games in the database.
  """
  def game_stats do
    total_games = Repo.aggregate(Game, :count, :id)
    
    old_games = 
      from(g in Game, 
        where: g.inserted_at < ^DateTime.add(DateTime.utc_now(), -24, :hour),
        select: count(g.id)
      )
      |> Repo.one()

    %{
      total_games: total_games,
      old_games: old_games,
      recent_games: total_games - old_games
    }
  end
end
