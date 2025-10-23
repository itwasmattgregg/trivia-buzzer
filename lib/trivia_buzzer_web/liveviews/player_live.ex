defmodule TriviaBuzzerWeb.PlayerLive do
  use TriviaBuzzerWeb, :live_view

  alias TriviaBuzzer.{Games, Players}
  alias Phoenix.PubSub

  @impl true
  def mount(%{"game_code" => game_code} = params, _session, socket) do
    case Games.get_game_by_code(game_code) do
      nil ->
        {:ok, 
          socket
          |> assign(game: nil, player: nil, game_code: game_code, player_name: "")
          |> put_flash(:error, "Game not found")
        }
      game ->
        PubSub.subscribe(TriviaBuzzer.PubSub, "game:#{game.id}")
        # Check if player_name is in URL params (from form submission)
        player_name = Map.get(params, "player_name", "")
        
        # Check if there's a stored player ID for this game
        stored_player_id = Map.get(params, "stored_player_id")
        
        socket = assign(socket, 
          game: game, 
          player: nil, 
          game_code: game_code, 
          player_name: player_name
        )
        
        # First, try to load existing player from stored ID
        if stored_player_id do
          case Players.get_player(stored_player_id) do
            nil ->
              # Stored player doesn't exist anymore, continue with normal flow
              socket = handle_player_join(socket, player_name)
              {:ok, socket}
            existing_player ->
              # Verify the player belongs to this game
              if existing_player.game_id == game.id do
                IO.inspect("Restored existing player: #{existing_player.name}")
                {:ok, assign(socket, player: existing_player, player_name: existing_player.name)}
              else
                # Player belongs to different game, continue with normal flow
                socket = handle_player_join(socket, player_name)
                {:ok, socket}
              end
          end
        else
          # No stored player, proceed with normal join flow
          socket = handle_player_join(socket, player_name)
          {:ok, socket}
        end
    end
  end

  @impl true
  def handle_event("join_game", %{"player_name" => name}, socket) do
    IO.inspect("Join game event received with name: #{name}")
    case Players.create_player(%{
      name: name,
      game_id: socket.assigns.game.id
    }) do
      {:ok, player} ->
        IO.inspect("Player created successfully: #{player.name}")
        IO.inspect("Broadcasting player_joined event for: #{player.name}")
        PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:player_joined, player})
        {:noreply, 
          socket
          |> assign(player: player, player_name: name)
          |> push_event("store_player_id", %{player_id: player.id, game_code: socket.assigns.game_code})
        }
      {:error, changeset} ->
        IO.inspect("Failed to create player: #{inspect(changeset)}")
        {:noreply, put_flash(socket, :error, "Failed to join game")}
    end
  end

  @impl true
  def handle_event("restore_player", %{"player_id" => player_id}, socket) do
    case Players.get_player(player_id) do
      nil ->
        # Player doesn't exist anymore, continue normally
        {:noreply, socket}
      player ->
        # Verify the player belongs to this game
        if player.game_id == socket.assigns.game.id do
          IO.inspect("Restored existing player: #{player.name}")
          {:noreply, assign(socket, player: player, player_name: player.name)}
        else
          # Player belongs to different game, continue normally
          {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_event("click_buzzer", _params, socket) do
    cond do
      is_nil(socket.assigns.player) ->
        {:noreply, put_flash(socket, :error, "You must join the game first")}
      socket.assigns.game.state != "open" ->
        {:noreply, put_flash(socket, :error, "Buzzers are not open")}
      true ->
        # Immediately update local state to prevent double-clicks
        updated_game = %{socket.assigns.game | state: "buzzed", winner_id: socket.assigns.player.id}
        PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:buzzer_clicked, socket.assigns.player})
        {:noreply, assign(socket, game: updated_game)}
    end
  end

  @impl true
  def handle_info({:game_state_changed, state}, socket) do
    updated_game = %{socket.assigns.game | state: state}
    {:noreply, assign(socket, game: updated_game)}
  end

  @impl true
  def handle_info({:player_joined, _player}, socket) do
    # Another player joined, we don't need to do anything special
    {:noreply, socket}
  end

  @impl true
  def handle_info({:buzzer_clicked, winner}, socket) do
    updated_game = %{socket.assigns.game | state: "buzzed", winner_id: winner.id}
    {:noreply, assign(socket, game: updated_game)}
  end

  @impl true
  def handle_info({:player_removed, player_id}, socket) do
    # If this player was removed, kick them back to join game state
    if socket.assigns.player && socket.assigns.player.id == String.to_integer(player_id) do
      {:noreply, 
        socket
        |> assign(player: nil, player_name: "")
        |> put_flash(:info, "You have been removed from the game")
        |> push_event("clear_player_id", %{game_code: socket.assigns.game_code})
      }
    else
      {:noreply, socket}
    end
  end

  # Helper function to handle player joining logic
  defp handle_player_join(socket, player_name) do
    if player_name != "" do
      # Auto-join if player name is provided
      case Players.create_player(%{
        name: player_name,
        game_id: socket.assigns.game.id
      }) do
        {:ok, player} ->
          IO.inspect("Broadcasting player_joined event for: #{player.name}")
          PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:player_joined, player})
          socket
          |> assign(player: player, player_name: player_name)
          |> push_event("store_player_id", %{player_id: player.id, game_code: socket.assigns.game_code})
        {:error, _changeset} ->
          socket
      end
    else
      socket
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="player-game-container" class="container" phx-hook="PlayerGame" data-game-code={@game_code}>
      <div class="hero">
        <div class="hero-content">
          <h1 class="hero-title">Trivia Buzzer</h1>
        </div>
      </div>
      
      <%= if @game do %>
        <%= if @player do %>
          <div class="game-info">
            <h2><%= @game.name %></h2>
            <div class="game-details">
              <div class="detail-item">
                <strong>Game Code:</strong> 
                <span class="game-code"><%= @game.game_code %></span>
              </div>
              <div class="detail-item">
                <strong>Status:</strong> 
                <span class={"status-badge status-#{@game.state}"}>
                  <%= String.capitalize(@game.state) %>
                </span>
              </div>
            </div>
          </div>
          <div class="player-info">
            <div class="glass-card">
              <h3>Welcome, <%= @player.name %>!</h3>
              
              <%= if @game.state == "open" do %>
                <div class="game-controls">
                  <button 
                    phx-click="click_buzzer" 
                    class="buzzer-button"
                    disabled={@game.state != "open"}
                  >
                    BUZZ!
                  </button>
                </div>
              <% else %>
                <div class="game-status">
                  <%= if @game.state == "locked" do %>
                    <p>Buzzers are locked. Waiting for admin to open them.</p>
                  <% else %>
                    <p>Buzzers are closed. Someone already buzzed!</p>
                    <%= if @game.winner_id == @player.id do %>
                      <p class="winner-message">You buzzed first!</p>
                    <% end %>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% else %>
          <div class="glass-card">
            <h3>Join the Game</h3>
            <p>Enter your name to join the game:</p>
            <form phx-submit="join_game">
              <div class="form-group">
                <label for="player_name">Your Name:</label>
                <input 
                  type="text" 
                  id="player_name" 
                  name="player_name" 
                  value={@player_name}
                  required 
                  class="form-control"
                  placeholder="Enter your name"
                />
              </div>
              <button type="submit" class="btn btn-primary btn-large">Join Game</button>
            </form>
          </div>
        <% end %>
      <% else %>
        <div class="error">
          <p>Game not found. Please check the game code.</p>
        </div>
      <% end %>
    </div>
    """
  end
end
