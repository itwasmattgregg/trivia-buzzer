defmodule TriviaBuzzer.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  alias TriviaBuzzer.Repo
  alias TriviaBuzzer.Players.Player

  @doc """
  Returns the list of players for a game.
  """
  def list_players_for_game(game_id) do
    from(p in Player, where: p.game_id == ^game_id)
    |> Repo.all()
  end

  @doc """
  Gets a single player.
  """
  def get_player!(id), do: Repo.get!(Player, id)

  @doc """
  Gets a single player by ID, returns nil if not found.
  """
  def get_player(id) when is_integer(id), do: Repo.get(Player, id)
  def get_player(id) when is_binary(id) do
    case Integer.parse(id) do
      {int_id, ""} -> get_player(int_id)
      _ -> nil
    end
  end

  @doc """
  Creates a player.
  """
  def create_player(attrs \\ %{}) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a player.
  """
  def update_player(%Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a player.
  """
  def delete_player(%Player{} = player) do
    Repo.delete(player)
  end

  def delete_player(id) when is_integer(id) do
    case Repo.get(Player, id) do
      nil -> {:error, :not_found}
      player -> delete_player(player)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player changes.
  """
  def change_player(%Player{} = player, attrs \\ %{}) do
    Player.changeset(player, attrs)
  end
end
