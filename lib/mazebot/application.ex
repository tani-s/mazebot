defmodule Mazebot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MazebotWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Mazebot.PubSub},
      # Start Finch
      {Finch, name: Mazebot.Finch},
      # Start the Endpoint (http/https)
      MazebotWeb.Endpoint
      # Start a worker by calling: Mazebot.Worker.start_link(arg)
      # {Mazebot.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mazebot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MazebotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
