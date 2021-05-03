# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :easy_wire,
  ecto_repos: [EasyWire.Repo]

# Configures the endpoint
config :easy_wire, EasyWireWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QyDMe1xs4QjjaWBTCXa+ZpMLWIb2JK4IIQyaE9vogOZc0LD7ByQakqow5EsX0kyg",
  render_errors: [view: EasyWireWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: EasyWire.PubSub,
  live_view: [signing_salt: "g/rg/sYk"]

config :easy_wire, EasyWire.ServiceRouter, fn ->
  profile_ids =
    EasyWire.Types.id()
    |> Norm.gen()
    |> Enum.take(10)

  %{
    profiles: EasyWire.Profiles.InMemory.new(profile_ids: profile_ids),
    accounts: EasyWire.Accounts.InMemory.new(profile_ids: profile_ids),
    transactions:
      EasyWire.Transactions.DenormalizeFast.new(
        EasyWire.Transactions.InMemory.new(profile_ids: profile_ids)
      )
  }
end

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
