defmodule ServiceMesh.Middleware do
  @callback init(service :: atom(), opts :: Keyword.t()) :: Keyword.t()
  @callback call(next :: (() -> any()), opts :: Keyword.t()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def init(_service, opts) do
        opts
      end

      defoverridable init: 2
    end
  end
end
