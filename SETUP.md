# Trivia Buzzer Setup Guide

## Prerequisites

Before running this Phoenix application, you need to install:

1. **Elixir** (version 1.12 or later)
2. **Erlang/OTP** (version 24 or later)
3. **SQLite** (database will be created automatically)

### Installing Elixir and Erlang

#### On macOS (using Homebrew):
```bash
brew install elixir
```

#### On Ubuntu/Debian:
```bash
# Install Erlang
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt-get update
sudo apt-get install erlang

# Install Elixir
sudo apt-get install elixir
```

#### On Windows:
Download and install from the official Elixir website: https://elixir-lang.org/install.html

### Installing SQLite

SQLite is usually pre-installed on most systems. If not:

#### On macOS:
```bash
brew install sqlite
```

#### On Ubuntu/Debian:
```bash
sudo apt-get install sqlite3 libsqlite3-dev
```

#### On Windows:
SQLite comes bundled with Erlang/OTP, no separate installation needed.

## Setup Instructions

1. **Install dependencies:**
   ```bash
   mix deps.get
   ```

2. **Set up the database (creates SQLite DB, runs migrations, seeds):**
   ```bash
   mix ecto.setup
   ```
   This creates `priv/dev.db`, runs migrations, and loads seeds. With SQLite you don't need a separate database server.

3. **Start the Phoenix server:**
   ```bash
   mix phx.server
   ```

4. **Open your browser and visit:**
   - Admin interface: `http://localhost:4000`
   - Player interface: `http://localhost:4000/game/[GAME_CODE]`

## How to Use the App

### For Admins:

1. **Create a Game:**
   - Visit `http://localhost:4000`
   - Enter a game name and click "Create Game"
   - You'll receive a game code and admin token
   - Share the game code with players

2. **Manage the Game:**
   - See all players who have joined
   - Click "Open Buzzers" to allow players to buzz in
   - When someone buzzes, you'll see who buzzed first
   - Click "Reset Game" to start over

### For Players:

1. **Join a Game:**
   - Visit `http://localhost:4000/game/[GAME_CODE]`
   - Enter your name and click "Join Game"
   - Wait for the admin to open buzzers

2. **Buzz In:**
   - When buzzers are open, click the big red "BUZZ!" button
   - The first person to buzz will be the winner
   - Wait for the admin to reset the game for the next round

## Game States

- **Locked**: Default state, no one can buzz
- **Open**: Admin has opened buzzers, players can buzz in
- **Buzzed**: Someone has buzzed, all buzzers are locked

## Features

- Real-time updates using Phoenix LiveView
- Custom game URLs with unique codes
- Admin controls for game state
- Player management
- Responsive design for mobile and desktop
- No authentication required (simple trivia buzzer)

## Troubleshooting

### Database Issues:
```bash
# Reset the database (drops, creates, migrates, seeds)
mix ecto.reset

# Or create DB and run migrations only
mix ecto.create
mix ecto.migrate
```
The SQLite database lives at `priv/dev.db` (dev) or `priv/test.db` (test). Deleting that file and running `mix ecto.setup` gives you a fresh database.

### Port Issues:
If port 4000 is in use, you can change it by setting the PORT environment variable:
```bash
PORT=4001 mix phx.server
```

### Dependencies Issues:
```bash
# Clean and reinstall dependencies
mix deps.clean --all
mix deps.get
```
