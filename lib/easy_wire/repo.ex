defmodule EasyWire.Repo do
  use Ecto.Repo,
    otp_app: :easy_wire,
    adapter: Ecto.Adapters.Postgres
end
