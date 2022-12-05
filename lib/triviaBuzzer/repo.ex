defmodule TriviaBuzzer.Repo do
  use Ecto.Repo,
    otp_app: :triviaBuzzer,
    adapter: Ecto.Adapters.Postgres
end
