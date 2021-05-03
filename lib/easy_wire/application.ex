defmodule EasyWire.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      EasyWire.Repo,
      EasyWireWeb.Telemetry,
      {Phoenix.PubSub, name: EasyWire.PubSub},
      {ServiceMesh, EasyWire.ServiceRouter},
      EasyWireWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: EasyWire.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    EasyWireWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
