defmodule ServiceMesh.Middleware.SimulateNetworkFailure do
  use ServiceMesh.Middleware

  @impl ServiceMesh.Middleware
  def call(next, opts) do
    failure_rate = Keyword.get(opts, :failure_rate, 0.01)

    if :rand.uniform() < failure_rate do
      {:error, :econnrefused}
    else
      next.()
    end
  end
end
