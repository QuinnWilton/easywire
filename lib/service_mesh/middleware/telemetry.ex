defmodule ServiceMesh.Middleware.Telemetry do
  use ServiceMesh.Middleware

  @impl ServiceMesh.Middleware
  def init(service, opts) do
    Keyword.put(opts, :service, service)
  end

  @impl ServiceMesh.Middleware
  def call(next, opts) do
    service = Keyword.fetch!(opts, :service)

    start_time = start(service)

    try do
      result = next.()
      stop(service, start_time)
      result
    rescue
      error ->
        exception(service, start_time, :error, error, __STACKTRACE__)
        reraise error, __STACKTRACE__
    end
  end

  defp start(event) do
    start_time = System.monotonic_time()
    measurements = %{system_time: System.system_time()}

    :telemetry.execute(
      [:service_mesh, event, :start],
      measurements
    )

    start_time
  end

  defp stop(event, start_time) do
    end_time = System.monotonic_time()
    measurements = %{duration: end_time - start_time}

    :telemetry.execute(
      [:service_mesh, event, :stop],
      measurements
    )
  end

  defp exception(event, start_time, kind, reason, stack) do
    end_time = System.monotonic_time()
    measurements = %{duration: end_time - start_time}

    meta =
      %{}
      |> Map.put(:kind, kind)
      |> Map.put(:error, reason)
      |> Map.put(:stacktrace, stack)

    :telemetry.execute([:service_mesh, event, :exception], measurements, meta)
  end
end
