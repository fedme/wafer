defmodule Wafer.Repo.Migrations.CreateReservations do
  use Ecto.Migration

  def change do
    create table(:reservations) do
      add :start, :utc_datetime
      add :end, :utc_datetime
      add :owner, :string
      add :resource, :string
      add :details, :map

      timestamps(type: :utc_datetime)
    end
  end
end
