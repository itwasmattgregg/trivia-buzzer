# Trivia Buzzer

A Phoenix LiveView application for running online trivia games with real-time buzzers.

## Features

- **Admin Interface**: Create games, manage players, control buzzer states
- **Player Interface**: Join games with a simple code, buzz in when ready
- **Real-time Updates**: Live synchronization between admin and players
- **Game States**: Locked → Open → Buzzed → Reset cycle
- **No Authentication**: Simple, fast setup for trivia games

## Quick Start

1. **Install Elixir and PostgreSQL** (see SETUP.md for detailed instructions)
2. **Setup the app:**
   ```bash
   mix deps.get
   mix ecto.setup
   mix phx.server
   ```
3. **Visit `http://localhost:4000`** to start creating games!

## How It Works

1. **Admin creates a game** → Gets a unique game code
2. **Players join** using the game code at `/game/[CODE]`
3. **Admin opens buzzers** → Players can buzz in
4. **First buzzer wins** → All others are locked
5. **Admin resets** → Ready for next question

## Game States

- **Locked**: Default state, buzzers disabled
- **Open**: Players can buzz in
- **Buzzed**: Someone buzzed, all locked

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
