defmodule TriviaBuzzer.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias TriviaBuzzer.Repo
  alias TriviaBuzzer.Games.Game

  @doc """
  Returns the list of games.
  """
  def list_games do
    Repo.all(Game)
  end

  @doc """
  Gets a single game.
  """
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Gets a game by game code.
  """
  def get_game_by_code(game_code) do
    Repo.get_by(Game, game_code: game_code)
  end

  @doc """
  Gets a game by admin token.
  """
  def get_game_by_admin_token(admin_token) do
    Repo.get_by(Game, admin_token: admin_token)
  end

  @doc """
  Creates a game.
  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game.
  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game.
  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.
  """
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  @doc """
  Updates the game state.
  """
  def update_game_state(%Game{} = game, state) do
    update_game(game, %{state: state})
  end

  @doc """
  Sets the winner of a game.
  """
  def set_winner(%Game{} = game, winner_id) do
    update_game(game, %{winner_id: winner_id, state: "buzzed"})
  end

  @doc """
  Resets the game state.
  """
  def reset_game(%Game{} = game) do
    update_game(game, %{state: "locked", winner_id: nil})
  end
end
