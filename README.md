# Trivia Buzzer

A Phoenix LiveView application for running online trivia games with real-time buzzers and team management.

## Features

- **Admin Interface**: Create games, manage players, control buzzer states, and organize teams
- **Player Interface**: Join games with a simple code, buzz in when ready, join teams
- **Team Management**: Create teams, assign players, track team performance
- **Real-time Updates**: Live synchronization between admin and players
- **Game States**: Locked → Open → Buzzed → Reset cycle
- **Smart Team Switching**: Players can only switch teams when buzzers are locked
- **Winner Highlighting**: Visual indicators for winning teams and players
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
3. **Admin creates teams** → Organize players into teams with custom names
4. **Players join teams** → Click team boxes to join (only when buzzers are locked)
5. **Admin opens buzzers** → Players can buzz in
6. **First buzzer wins** → Winning team and player are highlighted
7. **Admin resets** → Ready for next question, teams remain organized

## Game States

- **Locked**: Default state, buzzers disabled, team switching allowed
- **Open**: Players can buzz in, team switching disabled
- **Buzzed**: Someone buzzed, all locked, winning team highlighted

## Team Management

### For Admins:
- **Create Teams**: Add teams with custom names
- **Delete Teams**: Remove teams (players are automatically removed)
- **View Team Performance**: See which team buzzed first
- **Team Highlighting**: Winning teams get special visual treatment

### For Players:
- **Join Teams**: Click team boxes to join (only when buzzers are locked)
- **Leave Teams**: Switch between teams or leave entirely
- **Team Restrictions**: Cannot switch teams during active gameplay
- **Visual Feedback**: Clear indicators for team membership and availability

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
