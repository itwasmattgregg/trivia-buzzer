defmodule TriviaBuzzer.Scheduler.CleanupScheduler do
  @moduledoc """
  GenServer that schedules daily cleanup of old games.
  """

  use GenServer
  require Logger

  alias TriviaBuzzer.Games.Cleanup

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Server callbacks

  @impl true
  def init(state) do
    # Schedule the first cleanup
    schedule_next_cleanup()
    {:ok, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    Logger.info("Running daily cleanup of old games")
    
    count = Cleanup.cleanup_old_games()
    Logger.info("Cleanup completed: removed #{count} old games")
    
    # Schedule the next cleanup (24 hours from now)
    schedule_next_cleanup()
    
    {:noreply, state}
  end

  defp schedule_next_cleanup do
    # Calculate seconds until next 2 AM UTC
    now = DateTime.utc_now()
    tomorrow_2am = DateTime.new!(Date.add(now, 1), ~T[02:00:00], "Etc/UTC")
    seconds_until_2am = DateTime.diff(tomorrow_2am, now, :second)
    
    Process.send_after(self(), :cleanup, seconds_until_2am * 1000)
    Logger.info("Next cleanup scheduled in #{seconds_until_2am} seconds")
  end
end
