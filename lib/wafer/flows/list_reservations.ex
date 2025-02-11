defmodule Wafer.Flows.ListReservations do
  @moduledoc """
  Flow that allows the user to list their reservations.
  """

  alias Wafer.FlowState
  alias Wafer.WhatsApp
  alias Wafer.Reservations
  alias Wafer.Reservations.Reservation

  @behaviour Wafer.Flow

  @impl Wafer.Flow
  def init(state) do
    {:ok, state}
  end

  @impl Wafer.Flow
  def handle_inbound_message(_message, %FlowState{contact_phone: owner} = state) do
    reservations = Reservations.list_reservations(owner)

    reply =
      WhatsApp.text_message(
        state.contact_phone,
        "Here are your reservations:\n" <>
          Enum.map_join(reservations, "\n", &format_reservation/1)
      )

    {:reply_and_end, reply, state}
  end

  def format_reservation(%Reservation{
        start: start,
        end: end_time,
        resource: resource,
        details: details
      }) do
    datetime =
      Calendar.strftime(start, "%d/%m/%Y %H:%M") <> " - " <> Calendar.strftime(end_time, "%H:%M")

    resource =
      case resource do
        :desk -> "Desk #{details["desk_number"]}"
        :meeting_room -> "Meeting room #{details["room_number"]}"
      end

    "* #{datetime} #{resource}"
  end
end
