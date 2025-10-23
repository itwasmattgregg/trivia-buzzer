defmodule TriviaBuzzerWeb.PlayerLive do
  use TriviaBuzzerWeb, :live_view

  alias TriviaBuzzer.{Games, Players}
  alias Phoenix.PubSub

  @impl true
  def mount(%{"game_code" => game_code}, _session, socket) do
    case Games.get_game_by_code(game_code) do
      nil ->
        {:ok, 
          socket
          |> assign(game: nil, player: nil, game_code: game_code, player_name: "")
          |> put_flash(:error, "Game not found")
        }
      game ->
        PubSub.subscribe(TriviaBuzzer.PubSub, "game:#{game.id}")
        {:ok, assign(socket, 
          game: game, 
          player: nil, 
          game_code: game_code, 
          player_name: ""
        )}
    end
  end

  @impl true
  def handle_event("join_game", %{"player_name" => name}, socket) do
    case Players.create_player(%{
      name: name,
      game_id: socket.assigns.game.id
    }) do
      {:ok, player} ->
        PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:player_joined, player})
        {:noreply, assign(socket, player: player, player_name: name)}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to join game")}
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
        PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{socket.assigns.game.id}", {:buzzer_clicked, socket.assigns.player})
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:game_state_changed, _state}, socket) do
    # Don't fetch from database to avoid loops, just update the state
    {:noreply, socket}
  end

  @impl true
  def handle_info({:player_joined, _player}, socket) do
    # Another player joined, we don't need to do anything special
    {:noreply, socket}
  end

  @impl true
  def handle_info({:buzzer_clicked, _winner}, socket) do
    # Don't fetch from database to avoid loops
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="player-container">
      <h1>Trivia Buzzer</h1>
      
      <%= if @game do %>
        <div class="game-info">
          <h2><%= @game.name %></h2>
          <p>Game Code: <%= @game.game_code %></p>
          <p>State: <%= @game.state %></p>
        </div>

        <%= if @player do %>
          <div class="player-info">
            <p>Welcome, <%= @player.name %>!</p>
            
            <%= if @game.state == "open" do %>
              <button 
                phx-click="click_buzzer" 
                class="buzzer-button"
                disabled={@game.state != "open"}
              >
                BUZZ!
              </button>
            <% else %>
              <div class="buzzer-status">
                <%= if @game.state == "locked" do %>
                  <p>Buzzers are locked. Waiting for admin to open them.</p>
                <% else %>
                  <p>Buzzers are closed. Someone already buzzed!</p>
                  <%= if @game.winner_id == @player.id do %>
                    <p class="winner-message">🎉 You buzzed first! 🎉</p>
                  <% end %>
                <% end %>
              </div>
            <% end %>
          </div>
        <% else %>
          <div class="join-game">
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
              <button type="submit" class="btn btn-primary">Join Game</button>
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
