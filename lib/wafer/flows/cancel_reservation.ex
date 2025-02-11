defmodule Wafer.Flows.CancelReservation do
  @moduledoc """
  Flow that allows the user to cancel one of their reservations.
  """

  alias Wafer.FlowState
  alias Wafer.WhatsApp
  alias Wafer.Reservations
  alias Wafer.Reservations.Reservation
  import Wafer.FlowState, only: [assign: 3]

  @behaviour Wafer.Flow

  @impl Wafer.Flow
  def init(state) do
    {:ok, assign(state, :step, "reservation_selection")}
  end

  # Select reservation to cancel

  @impl Wafer.Flow
  def handle_inbound_message(
        _message,
        %FlowState{contact_phone: owner, assigns: %{step: "reservation_selection"}} = state
      ) do
    reservations = Reservations.list_reservations(owner)

    reply =
      WhatsApp.list_message(
        state.contact_phone,
        "Which reservation would you like to cancel?",
        "Select reservation",
        Enum.map(reservations, &format_reservation/1)
      )

    {:reply, reply, assign(state, :step, "confirmation")}
  end

  # Show confirmation
  def handle_inbound_message(message, %FlowState{assigns: %{step: "confirmation"}} = state) do
    {reservation_id, _} = WhatsApp.parse_answer(message)

    {:ok, _} =
      reservation_id
      |> String.to_integer()
      |> Reservations.get_reservation!()
      |> Reservations.delete_reservation()

    reply = WhatsApp.text_message(state.contact_phone, "Reservation cancelled!")

    {:reply_and_end, reply, state}
  end

  def format_reservation(%Reservation{
        id: id,
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

    {to_string(id), resource, datetime}
  end
end
