defmodule TriviaBuzzer.Repo do
  use Ecto.Repo,
    otp_app: :trivia_buzzer,
    adapter: Ecto.Adapters.Postgres
end
