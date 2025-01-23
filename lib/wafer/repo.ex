defmodule Wafer.Repo do
  use Ecto.Repo,
    otp_app: :wafer,
    adapter: Ecto.Adapters.Postgres
end
