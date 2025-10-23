defmodule TriviaBuzzerWeb.AdminGameLive do
  use TriviaBuzzerWeb, :live_view

  alias TriviaBuzzer.{Games, Players}
  alias Phoenix.PubSub

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    case Games.get_game!(game_id) do
      nil ->
        {:ok, 
          socket
          |> assign(game: nil, players: [])
          |> put_flash(:error, "Game not found")
        }
      game ->
        PubSub.subscribe(TriviaBuzzer.PubSub, "game:#{game.id}")
        players = Players.list_players_for_game(game.id)
        {:ok, assign(socket, game: game, players: players)}
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
  def handle_info({:player_joined, player}, socket) do
    players = [player | socket.assigns.players]
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def handle_info({:buzzer_clicked, player}, socket) do
    case Games.set_winner(socket.assigns.game, player.id) do
      {:ok, updated_game} ->
        PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:buzzer_clicked, player})
        {:noreply, assign(socket, game: updated_game)}
      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:game_state_changed, _state}, socket) do
    # Don't fetch from database to avoid loops
    {:noreply, socket}
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
  def render(assigns) do
    ~H"""
    <div class="admin-container">
      <div class="admin-header">
        <h1>🎪 Game Control Center</h1>
        <p>Manage your trivia game in real-time</p>
      </div>
      
      <%= if @game do %>
        <div class="game-info">
          <h2>📝 Game: <%= @game.name %></h2>
          <div class="game-details">
            <div class="detail-item">
              <strong>Game Code:</strong> 
              <span class="game-code"><%= @game.game_code %></span>
              <button 
                phx-click="copy_code" 
                class="btn btn-small btn-outline"
                data-code={@game.game_code}
              >
                📋 Copy
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
              </div>
            <% end %>
          </div>
        </div>

        <div class="game-controls">
          <%= if @game.state == "locked" do %>
            <button phx-click="open_buzzers" class="btn btn-primary btn-large">
              🚀 Open Buzzers
            </button>
            <p class="control-hint">Click to allow players to buzz in</p>
          <% end %>
          <%= if @game.state == "open" do %>
            <div class="waiting-state">
              <p class="waiting-message">⏳ Buzzers are open! Waiting for players to buzz...</p>
            </div>
          <% end %>
          <%= if @game.state == "buzzed" do %>
            <button phx-click="reset_game" class="btn btn-secondary btn-large">
              🔄 Reset Game
            </button>
            <p class="control-hint">Click to start the next question</p>
          <% end %>
        </div>

        <div class="players-section">
          <h3>👥 Players (<%= length(@players) %>)</h3>
          <%= if length(@players) == 0 do %>
            <div class="no-players">
              <p>No players have joined yet. Share the game code to get started!</p>
            </div>
          <% else %>
            <div class="players-list">
              <%= for player <- @players do %>
                <div class="player-item">
                  <span class="player-name"><%= player.name %></span>
                  <%= if @game.winner_id == player.id do %>
                    <span class="winner-badge">🏆 Winner!</span>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <div class="share-section">
          <h3>📤 Share Your Game</h3>
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
              class="btn btn-small"
              data-link={"http://localhost:4000/game/#{@game.game_code}"}
            >
              📋 Copy Link
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
end
