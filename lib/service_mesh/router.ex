defmodule ServiceMesh.Router do
  require Logger

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote do
      Module.register_attribute(__MODULE__, :middleware, accumulate: true)
      Module.register_attribute(__MODULE__, :services, accumulate: true)

      @before_compile ServiceMesh.Router
      import ServiceMesh.Router

      def runtime_config() do
        Application.get_env(unquote(otp_app), __MODULE__, fn -> %{} end).()
      end

      defoverridable runtime_config: 0
    end
  end

  defmacro __before_compile__(env) do
    middleware =
      env.module
      |> Module.get_attribute(:middleware)
      |> Enum.reverse()

    services =
      Module.get_attribute(env.module, :services)
      |> Enum.into(%{})
      |> Macro.escape()

    quote do
      def __middleware__() do
        unquote(middleware)
      end

      def __services__() do
        Map.keys(unquote(services))
      end

      def __service__(service) do
        Map.get(unquote(services), service)
      end

      def dispatch(service, middleware, impl, function, args) do
        ServiceMesh.Router.dispatch(
          __MODULE__,
          service,
          middleware,
          impl,
          function,
          args
        )
      end
    end
  end

  defmacro middleware(middleware, opts \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :middleware,
        {unquote(middleware), unquote(opts)}
      )
    end
  end

  defmacro register(service, protocol) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :services,
        {unquote(service), unquote(protocol)}
      )
    end
  end

  def dispatch(router, service, middleware, impl, function, args) do
    protocol = router.__service__(service)

    call_service = fn ->
      apply(protocol, function, [impl | args])
    end

    continuation =
      Enum.reduce(middleware, call_service, fn {middleware, opts}, continuation ->
        fn ->
          apply(middleware, :call, [continuation, opts])
        end
      end)

    continuation.()
  end
end
