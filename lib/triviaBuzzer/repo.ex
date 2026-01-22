defmodule TriviaBuzzer.Repo do
  use Ecto.Repo,
    otp_app: :trivia_buzzer,
    adapter: Ecto.Adapters.SQLite3

  def init(_type, config) do
    {:ok, config}
  end
end
