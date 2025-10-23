defmodule TriviaBuzzerWeb.AdminGameLive do
  use TriviaBuzzerWeb, :live_view

  alias TriviaBuzzer.{Games, Players, Teams}
  alias Phoenix.PubSub

  @impl true
  def mount(%{"admin_token" => admin_token}, _session, socket) do
    case Games.get_game_by_admin_token(admin_token) do
      nil ->
        {:ok, 
          socket
          |> assign(game: nil, players: [])
          |> put_flash(:error, "Game not found")
        }
      game ->
        PubSub.subscribe(TriviaBuzzer.PubSub, "game:#{game.id}")
        players = Players.list_players_for_game(game.id)
        teams = Teams.list_teams_for_game(game.id)
        {:ok, assign(socket, game: game, players: players, teams: teams)}
    end
  end




  @impl true
  def handle_event("open_buzzers", _params, socket) do
    case Games.update_game_state(socket.assigns.game, "open") do
      {:ok, updated_game} ->
        PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:game_state_changed, "open"})
        {:noreply, assign(socket, game: updated_game)}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to open buzzers")}
    end
  end

  @impl true
  def handle_event("close_buzzers", _params, socket) do
    case Games.update_game_state(socket.assigns.game, "locked") do
      {:ok, updated_game} ->
        PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:game_state_changed, "locked"})
        {:noreply, assign(socket, game: updated_game)}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to close buzzers")}
    end
  end

  @impl true
  def handle_event("reset_game", _params, socket) do
    case Games.reset_game(socket.assigns.game) do
      {:ok, updated_game} ->
        PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:game_state_changed, "locked"})
        {:noreply, assign(socket, game: updated_game)}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reset game")}
    end
  end

  @impl true
  def handle_event("copy_code", _params, socket) do
    {:noreply, put_flash(socket, :info, "Game code copied to clipboard!")}
  end

  @impl true
  def handle_event("copy_link", _params, socket) do
    {:noreply, put_flash(socket, :info, "Game link copied to clipboard!")}
  end


  @impl true
  def handle_event("delete_player", %{"player_id" => player_id}, socket) do
    player_id_int = String.to_integer(player_id)
    
    case Players.delete_player(player_id_int) do
      {:ok, _player} ->
        # Remove player from local list
        updated_players = Enum.reject(socket.assigns.players, &(&1.id == player_id_int))
        # Broadcast player removal to all clients
        PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:player_removed, player_id})
        {:noreply, assign(socket, players: updated_players)}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove player")}
    end
  end

  @impl true
  def handle_event("create_team", %{"team_name" => team_name}, socket) do
    case Teams.create_team(%{name: team_name, game_id: socket.assigns.game.id}) do
      {:ok, team} ->
        # Reload teams with players
        teams = Teams.list_teams_for_game(socket.assigns.game.id)
        # Broadcast team creation to all clients
        PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:team_created, team})
        {:noreply, assign(socket, teams: teams)}
      {:error, changeset} ->
        error_message = case changeset.errors do
          [name: {"has already been taken", _}] -> "A team with this name already exists"
          _ -> "Failed to create team"
        end
        {:noreply, put_flash(socket, :error, error_message)}
    end
  end

  @impl true
  def handle_event("delete_team", %{"team_id" => team_id}, socket) do
    team_id_int = String.to_integer(team_id)
    
    # Find the team in the current teams list
    case Enum.find(socket.assigns.teams, &(&1.id == team_id_int)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Team not found")}
      team ->
        case Teams.delete_team(team) do
          {:ok, _team} ->
            # Remove team from local list
            updated_teams = Enum.reject(socket.assigns.teams, &(&1.id == team_id_int))
            # Broadcast team deletion to all clients
            PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:team_deleted, team_id})
            {:noreply, assign(socket, teams: updated_teams)}
          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to delete team")}
        end
    end
  end


  @impl true
  def handle_info({:player_joined, player}, socket) do
    players = [player | socket.assigns.players]
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def handle_info({:player_removed, player_id}, socket) do
    updated_players = Enum.reject(socket.assigns.players, &(&1.id == String.to_integer(player_id)))
    {:noreply, assign(socket, players: updated_players)}
  end


  @impl true
  def handle_info({:buzzer_clicked, player}, socket) do
    # Only process buzzer clicks if the game is currently open
    if socket.assigns.game.state == "open" do
      case Games.set_winner(socket.assigns.game, player.id) do
        {:ok, updated_game} ->
          PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:buzzer_clicked, player})
          {:noreply, assign(socket, game: updated_game)}
        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:game_state_changed, state}, socket) do
    updated_game = %{socket.assigns.game | state: state}
    {:noreply, assign(socket, game: updated_game)}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="admin-header">
        <h1>Game Control Center</h1>
        <p>Manage your trivia game in real-time</p>
      </div>
      
      <%= if @game do %>
        <div class="game-info">
          <h2>Game: <%= @game.name %></h2>
          <div class="game-details">
            <div class="detail-item">
              <strong>Game Code:</strong> 
              <span class="game-code"><%= @game.game_code %></span>
              <button 
                phx-click="copy_code" 
                class="btn btn-small btn-secondary"
                data-code={@game.game_code}
              >
                Copy
              </button>
            </div>
            <div class="detail-item">
              <strong>Admin Token:</strong> 
              <span class="admin-token"><%= @game.admin_token %></span>
            </div>
            <div class="detail-item">
              <strong>Status:</strong> 
              <span class={"status-badge status-#{@game.state}"}>
                <%= String.capitalize(@game.state) %>
              </span>
            </div>
            <%= if @game.winner_id do %>
              <div class="detail-item">
                <strong>Winner:</strong> 
                <span class="winner-name"><%= get_winner_name(@game.winner_id, @players) %></span>
                <%= if winner_team = get_winner_team(@game.winner_id, @teams) do %>
                  <span class="winner-team">(<%= winner_team.name %>)</span>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <div class="game-controls">
          <%= if @game.state == "locked" do %>
            <button phx-click="open_buzzers" class="btn btn-primary btn-large">
              Open Buzzers
            </button>
            <p class="control-hint">Click to allow players to buzz in</p>
          <% end %>
          <%= if @game.state == "open" do %>
            <button phx-click="close_buzzers" class="btn btn-secondary btn-large">
              Close Buzzers
            </button>
            <p class="control-hint">Buzzers are open! Waiting for players to buzz...</p>
          <% end %>
          <%= if @game.state == "buzzed" do %>
            <button phx-click="reset_game" class="btn btn-secondary btn-large">
              Reset Game
            </button>
            <p class="control-hint">Click to start the next question</p>
          <% end %>
        </div>

        <div class="players-list">
          <h3>Players (<%= length(@players) %>)</h3>
          <%= if length(@players) == 0 do %>
            <div class="no-players">
              <p>No players have joined yet. Share the game code to get started!</p>
            </div>
          <% else %>
            <%= for player <- @players do %>
              <div class="player-item">
                <span class="player-name"><%= player.name %></span>
                <%= if @game.winner_id == player.id do %>
                  <span class="winner-badge">Winner!</span>
                <% end %>
                <button 
                  phx-click="delete_player" 
                  phx-value-player_id={player.id}
                  class="btn btn-small btn-danger"
                  title="Remove player"
                >
                  ×
                </button>
              </div>
            <% end %>
          <% end %>
        </div>

        <div class="teams-section">
          <h3>Teams (<%= length(@teams) %>)</h3>
          <div class="team-management">
            <form phx-submit="create_team" class="team-form">
              <div class="form-group">
                <input 
                  type="text" 
                  name="team_name" 
                  placeholder="Enter team name" 
                  required 
                  class="form-control"
                />
                <button type="submit" class="btn btn-primary">Add Team</button>
              </div>
            </form>
          </div>
          
          <%= if length(@teams) == 0 do %>
            <div class="no-teams">
              <p>No teams created yet. Create teams to organize players!</p>
            </div>
          <% else %>
            <div class="teams-list">
              <%= for team <- @teams do %>
                <div class={"team-item #{if team_buzzed_first?(@game, team), do: "team-winner", else: ""}"}>
                  <div class="team-header">
                    <h4><%= team.name %></h4>
                    <%= if team_buzzed_first?(@game, team) do %>
                      <span class="team-winner-badge">Winner Team!</span>
                    <% end %>
                    <button 
                      phx-click="delete_team" 
                      phx-value-team_id={team.id}
                      class="btn btn-small btn-danger"
                      title="Delete team"
                    >
                      ×
                    </button>
                  </div>
                  <div class="team-members">
                    <%= if length(team.players) == 0 do %>
                      <p class="no-members">No members yet</p>
                    <% else %>
                      <%= for player <- team.players do %>
                        <span class={"team-member #{if @game.winner_id == player.id, do: "winner-player", else: ""}"}><%= player.name %></span>
                      <% end %>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <div class="share-section">
          <h3>Share Your Game</h3>
          <p>Send this link to your players:</p>
          <div class="share-link">
            <input 
              type="text" 
              value={"http://localhost:4000/game/#{@game.game_code}"}
              readonly 
              class="form-control"
            />
            <button 
              phx-click="copy_link" 
              class="btn btn-small btn-primary"
              data-link={"http://localhost:4000/game/#{@game.game_code}"}
            >
              Copy Link
            </button>
          </div>
        </div>
      <% else %>
        <div class="error">
          <p>Game not found. Please check the URL.</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_winner_name(winner_id, players) do
    case Enum.find(players, &(&1.id == winner_id)) do
      nil -> "Unknown"
      player -> player.name
    end
  end

  defp team_buzzed_first?(game, team) do
    if game.winner_id do
      Enum.any?(team.players, &(&1.id == game.winner_id))
    else
      false
    end
  end

  defp get_winner_team(winner_id, teams) do
    Enum.find(teams, fn team ->
      Enum.any?(team.players, &(&1.id == winner_id))
    end)
  end
end
