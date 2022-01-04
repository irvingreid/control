defmodule Control.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # OpenTelemetry.register_application_tracer(:control)

    OpentelemetryPhoenix.setup()
    OpentelemetryLiveView.setup()

    children = [
      # Start the Telemetry supervisor
      ControlWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Control.PubSub},
      # Start the Endpoint (http/https)
      ControlWeb.Endpoint
      # Start a worker by calling: Control.Worker.start_link(arg)
      # {Control.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Control.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ControlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
