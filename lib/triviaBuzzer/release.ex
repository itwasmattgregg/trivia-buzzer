defmodule TriviaBuzzer.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :trivia_buzzer

  def migrate do
    load_app()
  end

  def rollback(repo, version) do
    load_app()
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
