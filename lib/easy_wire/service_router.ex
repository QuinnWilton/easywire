defmodule EasyWire.ServiceRouter do
  use ServiceMesh.Router, otp_app: :easy_wire

  middleware ServiceMesh.Middleware.Telemetry

  register :accounts, EasyWire.Accounts.Service
  register :profiles, EasyWire.Profiles.Service
  register :transactions, EasyWire.Transactions.Service
end
