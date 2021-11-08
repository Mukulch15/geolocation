defmodule Geolocation.Repo do
  use Ecto.Repo,
    otp_app: :geolocation,
    adapter: Ecto.Adapters.Postgres
end
