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
        # Toast message will be handled by JavaScript
        {:noreply, socket}
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
    <!-- Structured Data for SEO -->
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "WebApplication",
      "name": "Trivia Buzzer",
      "description": "Create instant trivia games with real-time buzzers and team management. Perfect for online trivia nights, classroom quizzes, and team building events.",
      "url": "https://trivia-buzzer.com",
      "applicationCategory": "GameApplication",
      "operatingSystem": "Web Browser",
      "offers": {
        "@type": "Offer",
        "price": "0",
        "priceCurrency": "USD"
      },
      "creator": {
        "@type": "Person",
        "name": "Matt Gregg",
        "url": "https://codegregg.com"
      },
      "featureList": [
        "Real-time trivia games",
        "Team management",
        "Live buzzer system",
        "Mobile friendly",
        "No downloads required"
      ]
    }
    </script>
    
    <a href="#main-content" class="skip-link">Skip to main content</a>
    
    <div class="container">
      <!-- Hero Section -->
      <header class="hero" role="banner">
        <div class="hero-content">
          <h1 class="hero-title">Trivia Buzzer</h1>
          <p class="hero-subtitle">Real-time trivia games made simple</p>
          <p class="hero-description">
            Create instant trivia games with custom codes. Players join with a simple link and buzz in when ready. 
            Perfect for online trivia nights, classroom quizzes, and team building events.
          </p>
          <div style="margin-top: var(--space-lg);">
            <a href="/support" class="btn btn-secondary">
              💚 Support Development
            </a>
          </div>
        </div>
      </header>

      <!-- Action Cards -->
      <main id="main-content" role="main">
      <section class="action-cards" aria-label="Game actions">
        <!-- Join Game Card -->
        <article class="action-card">
          <h2>Join a game</h2>
          <p>Have a game code? Enter it below to join the fun!</p>
          <form phx-submit="join_game" class="join-form">
            <div class="form-group">
              <label for="game_code" class="sr-only">Game code</label>
              <input 
                type="text" 
                name="game_code" 
                id="game_code"
                value={@game_code}
                placeholder="Enter game code (e.g., abc123)"
                required 
                class="form-control"
                aria-label="Enter game code"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-large">Join Game</button>
          </form>
        </article>

        <!-- Create Game Card -->
        <article class="action-card">
          <h2>Create a game</h2>
          <p>Start your own trivia game and share the code with players!</p>
          <form phx-submit="create_game" class="create-form">
            <div class="form-group">
              <label for="game_name" class="sr-only">Game name</label>
              <input 
                type="text" 
                name="game_name" 
                id="game_name"
                value={@game_name}
                placeholder="Enter game name (e.g., Friday Night Trivia)"
                required 
                class="form-control"
                aria-label="Enter game name"
              />
            </div>
            <button type="submit" class="btn btn-success btn-large">Create Game</button>
          </form>
        </article>
      </section>

      <!-- Features Section -->
      <section class="glass-card" aria-labelledby="features-heading">
        <h2 id="features-heading" class="text-center mb-4">Why choose Trivia Buzzer?</h2>
        <div class="features-grid">
          <article class="feature">
            <div class="feature-icon" aria-hidden="true">⚡</div>
            <h3>Lightning fast</h3>
            <p>Real-time updates with zero lag. Players see changes instantly.</p>
          </article>
          <article class="feature">
            <div class="feature-icon" aria-hidden="true">👥</div>
            <h3>Team management</h3>
            <p>Create teams, organize players, and track team performance with visual indicators.</p>
          </article>
          <article class="feature">
            <div class="feature-icon" aria-hidden="true">🔗</div>
            <h3>Simple sharing</h3>
            <p>Just share a game code. No downloads, no accounts, no hassle.</p>
          </article>
          <article class="feature">
            <div class="feature-icon" aria-hidden="true">📱</div>
            <h3>Mobile friendly</h3>
            <p>Works perfectly on phones, tablets, and computers.</p>
          </article>
          <article class="feature">
            <div class="feature-icon" aria-hidden="true">🎯</div>
            <h3>Fair play</h3>
            <p>Smart team switching restrictions ensure fair competition during active gameplay.</p>
          </article>
        </div>
      </section>
      
      <!-- How It Works -->
      <section class="glass-card mt-5" aria-labelledby="how-it-works-heading">
        <h2 id="how-it-works-heading" class="text-center mb-4">How it works</h2>
        <ol class="steps">
          <li class="step">
            <h3>Create game</h3>
            <p>Enter a game name and get a unique code</p>
          </li>
          <li class="step">
            <h3>Share code</h3>
            <p>Send the code to your players via text, email, or chat</p>
          </li>
          <li class="step">
            <h3>Organize teams</h3>
            <p>Create teams with custom names and let players join their preferred team</p>
          </li>
          <li class="step">
            <h3>Start playing</h3>
            <p>Open buzzers, ask questions, and see which team buzzes first!</p>
          </li>
        </ol>
      </section>
      </main>
    </div>
    """
  end

  defp generate_game_code do
    :crypto.strong_rand_bytes(3) |> Base.encode32(case: :lower, padding: false)
  end

  defp generate_admin_token do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
