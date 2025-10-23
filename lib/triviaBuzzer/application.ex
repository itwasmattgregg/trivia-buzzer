defmodule TriviaBuzzer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      TriviaBuzzer.Repo,
      # Start the Telemetry supervisor
      TriviaBuzzerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: TriviaBuzzer.PubSub},
      # Start the Endpoint (http/https)
      TriviaBuzzerWeb.Endpoint
      # Start a worker by calling: TriviaBuzzer.Worker.start_link(arg)
      # {TriviaBuzzer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TriviaBuzzer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TriviaBuzzerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
