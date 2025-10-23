defmodule TriviaBuzzerWeb.HomeLive do
  use TriviaBuzzerWeb, :live_view

  alias TriviaBuzzer.Games

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, 
      game_code: "",
      game_name: "",
      flash_message: nil
    )}
  end

  @impl true
  def handle_event("join_game", %{"game_code" => game_code}, socket) do
    case Games.get_game_by_code(game_code) do
      nil ->
        {:noreply, put_flash(socket, :error, "Game not found. Please check the code.")}
      _game ->
        {:noreply, redirect(socket, to: "/game/#{game_code}")}
    end
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
        {:noreply, redirect(socket, to: "/admin/#{game.admin_token}")}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create game")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container">
      <!-- Hero Section -->
      <div class="hero">
        <div class="hero-content">
          <h1 class="hero-title">Trivia Buzzer</h1>
          <p class="hero-subtitle">Real-time trivia games made simple</p>
          <p class="hero-description">
            Create instant trivia games with custom codes. Players join with a simple link and buzz in when ready. 
            Perfect for online trivia nights, classroom quizzes, and team building events.
          </p>
        </div>
      </div>

      <!-- Action Cards -->
      <div class="action-cards">
        <!-- Join Game Card -->
        <div class="action-card">
          <h3>Join a game</h3>
          <p>Have a game code? Enter it below to join the fun!</p>
          <form phx-submit="join_game" class="join-form">
            <div class="form-group">
              <input 
                type="text" 
                name="game_code" 
                value={@game_code}
                placeholder="Enter game code (e.g., abc123)"
                required 
                class="form-control"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-large">Join Game</button>
          </form>
        </div>

        <!-- Create Game Card -->
        <div class="action-card">
          <h3>Create a game</h3>
          <p>Start your own trivia game and share the code with players!</p>
          <form phx-submit="create_game" class="create-form">
            <div class="form-group">
              <input 
                type="text" 
                name="game_name" 
                value={@game_name}
                placeholder="Enter game name (e.g., Friday Night Trivia)"
                required 
                class="form-control"
              />
            </div>
            <button type="submit" class="btn btn-success btn-large">Create Game</button>
          </form>
        </div>
      </div>

      <!-- Features Section -->
      <div class="glass-card">
        <h2 class="text-center mb-4">Why choose Trivia Buzzer?</h2>
        <div class="features-grid">
          <div class="feature">
            <div class="feature-icon">⚡</div>
            <h4>Lightning fast</h4>
            <p>Real-time updates with zero lag. Players see changes instantly.</p>
          </div>
          <div class="feature">
            <div class="feature-icon">👥</div>
            <h4>Team management</h4>
            <p>Create teams, organize players, and track team performance with visual indicators.</p>
          </div>
          <div class="feature">
            <div class="feature-icon">🔗</div>
            <h4>Simple sharing</h4>
            <p>Just share a game code. No downloads, no accounts, no hassle.</p>
          </div>
          <div class="feature">
            <div class="feature-icon">📱</div>
            <h4>Mobile friendly</h4>
            <p>Works perfectly on phones, tablets, and computers.</p>
          </div>
          <div class="feature">
            <div class="feature-icon">🎯</div>
            <h4>Fair play</h4>
            <p>Smart team switching restrictions ensure fair competition during active gameplay.</p>
          </div>
        </div>
      </div>
      
      <!-- How It Works -->
      <div class="glass-card mt-5">
        <h2 class="text-center mb-4">How it works</h2>
        <ol class="steps">
          <li class="step">
            <h4>Create game</h4>
            <p>Enter a game name and get a unique code</p>
          </li>
          <li class="step">
            <h4>Share code</h4>
            <p>Send the code to your players via text, email, or chat</p>
          </li>
          <li class="step">
            <h4>Organize teams</h4>
            <p>Create teams with custom names and let players join their preferred team</p>
          </li>
          <li class="step">
            <h4>Start playing</h4>
            <p>Open buzzers, ask questions, and see which team buzzes first!</p>
          </li>
        </ol>
      </div>
    </div>
    """
  end

  defp generate_game_code do
    :crypto.strong_rand_bytes(3) |> Base.encode32(case: :lower, padding: false)
  end

  defp generate_admin_token do
    :crypto.strong_rand_bytes(16) |> Base.encode64(padding: false)
  end
end
