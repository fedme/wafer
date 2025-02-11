defmodule Wafer.Reservations.Reservation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reservations" do
    field :start, :utc_datetime
    field :end, :utc_datetime
    field :owner, :string
    field :resource, Ecto.Enum, values: [:desk, :meeting_room]
    field :details, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, [:start, :end, :owner, :resource, :details])
    |> validate_required([:start, :end, :owner, :resource])
  end
end
