defmodule ServiceMesh do
  use Supervisor

  alias ServiceMesh.Router

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def call(name \\ Registry.ServiceMesh, service, function, args) do
    with {:ok, router} <- Registry.meta(name, :router),
         {:ok, {impl, middleware}} <-
           Registry.meta(
             name,
             {:service, service}
           ) do
      Router.dispatch(router, service, middleware, impl, function, args)
    end
  end

  @impl true
  def init(router) do
    children = [
      {Registry, keys: :unique, name: Registry.ServiceMesh},
      {Task, fn -> initialize_services(router) end}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp initialize_services(router) do
    middleware = router.__middleware__()
    services = router.__services__()
    config = router.runtime_config()

    :ok = Registry.put_meta(Registry.ServiceMesh, :router, router)

    Enum.each(services, fn service ->
      case Map.get(config, service) do
        nil ->
          raise ArgumentError, "missing service implementation for #{service}"

        implementation ->
          middleware =
            Enum.map(middleware, fn {middleware, opts} ->
              {middleware, middleware.init(service, opts)}
            end)

          :ok =
            Registry.put_meta(
              Registry.ServiceMesh,
              {:service, service},
              {implementation, middleware}
            )
      end
    end)
  end
end
