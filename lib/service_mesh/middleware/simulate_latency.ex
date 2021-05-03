defmodule ServiceMesh.Middleware.SimulateLatency do
  use ServiceMesh.Middleware

  @impl ServiceMesh.Middleware
  def call(next, opts) do
    latency = Keyword.get(opts, :latency, 100)

    :timer.sleep(latency)

    next.()
  end
end
