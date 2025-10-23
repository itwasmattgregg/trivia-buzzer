defmodule TriviaBuzzerWeb.AdminLive do
  use TriviaBuzzerWeb, :live_view

  alias TriviaBuzzer.Games
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, 
      game: nil,
      players: [],
      game_name: "",
      game_code: "",
      admin_token: ""
    )}
  end

  @impl true
  def handle_event("create_game", %{"game_name" => name}, socket) do
    game_code = generate_game_code()
    admin_token = generate_admin_token()
    
    case Games.create_game(%{
      name: name,
      game_code: game_code,
      admin_token: admin_token
    }) do
      {:ok, game} ->
        PubSub.subscribe(TriviaBuzzer.PubSub, "game:#{game.id}")
        {:noreply, assign(socket, 
          game: game,
          game_name: name,
          game_code: game_code,
          admin_token: admin_token
        )}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create game")}
    end
  end

  @impl true
  def handle_event("open_buzzers", _params, socket) do
    case socket.assigns.game do
      nil -> 
        {:noreply, put_flash(socket, :error, "No active game")}
      game ->
        case Games.update_game_state(game, "open") do
          {:ok, updated_game} ->
            PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{game.id}", {:game_state_changed, "open"})
            {:noreply, assign(socket, game: updated_game)}
          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to open buzzers")}
        end
    end
  end

  @impl true
  def handle_event("reset_game", _params, socket) do
    case socket.assigns.game do
      nil -> 
        {:noreply, put_flash(socket, :error, "No active game")}
      game ->
        case Games.reset_game(game) do
          {:ok, updated_game} ->
            PubSub.broadcast(TriviaBuzzer.PubSub, "game:#{game.id}", {:game_state_changed, "locked"})
            {:noreply, assign(socket, game: updated_game)}
          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to reset game")}
        end
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
  def render(assigns) do
    ~H"""
    <div class="admin-container">
      <h1>Trivia Buzzer admin</h1>
      
      <%= if @game do %>
        <div class="game-info">
          <h2>Game: <%= @game.name %></h2>
          <p><strong>Game Code:</strong> <%= @game.game_code %></p>
          <p><strong>Admin Token:</strong> <%= @game.admin_token %></p>
          <p><strong>State:</strong> <%= @game.state %></p>
          <%= if @game.winner_id do %>
            <p><strong>Winner:</strong> <%= get_winner_name(@game.winner_id, @players) %></p>
          <% end %>
        </div>

        <div class="game-controls">
          <%= if @game.state == "locked" do %>
            <button phx-click="open_buzzers" class="btn btn-primary">Open Buzzers</button>
          <% end %>
          <%= if @game.state == "buzzed" do %>
            <button phx-click="reset_game" class="btn btn-secondary">Reset Game</button>
          <% end %>
        </div>

        <div class="players-list">
          <h3>Players (<%= length(@players) %>)</h3>
          <ul>
            <%= for player <- @players do %>
              <li><%= player.name %></li>
            <% end %>
          </ul>
        </div>
      <% else %>
        <div class="create-game">
          <form phx-submit="create_game">
            <div class="form-group">
              <label for="game_name">Game Name:</label>
              <input 
                type="text" 
                id="game_name" 
                name="game_name" 
                value={@game_name}
                required 
                class="form-control"
              />
            </div>
            <button type="submit" class="btn btn-primary">Create Game</button>
          </form>
        </div>
      <% end %>
    </div>
    """
  end

  defp generate_game_code do
    :crypto.strong_rand_bytes(3) |> Base.encode32(case: :lower, padding: false)
  end

  defp generate_admin_token do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  defp get_winner_name(winner_id, players) do
    case Enum.find(players, &(&1.id == winner_id)) do
      nil -> "Unknown"
      player -> player.name
    end
  end
end
