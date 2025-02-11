defmodule Wafer.Flows.BookDesk do
  @moduledoc """
  Flow that allows the user to book a desk at the coworking space.
  """

  alias Wafer.FlowState
  alias Wafer.WhatsApp
  alias Wafer.Reservations
  import Wafer.FlowState, only: [assign: 3]

  @behaviour Wafer.Flow

  @impl Wafer.Flow
  def init(state) do
    {:ok, assign(state, :step, "date_selection")}
  end

  # Select date

  @impl Wafer.Flow
  def handle_inbound_message(_message, %FlowState{assigns: %{step: "date_selection"}} = state) do
    reply =
      WhatsApp.buttons_message(
        state.contact_phone,
        "When do you need the desk?",
        [
          {"today", "Today"},
          {"tomorrow", "Tomorrow"},
          {"the_day_after_tomorrow", "Day after tomorrow"}
        ]
      )

    {:reply, reply, assign(state, :step, "time_selection")}
  end

  # Select time

  def handle_inbound_message(message, %FlowState{assigns: %{step: "time_selection"}} = state) do
    {answer, _} = WhatsApp.parse_answer(message)

    state =
      state
      |> assign(:desk_date, answer)
      |> assign(:step, "floor_selection")

    reply =
      WhatsApp.buttons_message(
        state.contact_phone,
        "Do you need it for the full day or half day?",
        [
          {"full_day", "Full day"},
          {"morning", "Morning"},
          {"afternoon", "Afternoon"}
        ]
      )

    {:reply, reply, state}
  end

  # Select floor

  def handle_inbound_message(message, %FlowState{assigns: %{step: "floor_selection"}} = state) do
    {answer, _} = WhatsApp.parse_answer(message)

    state =
      state
      |> assign(:desk_time, answer)
      |> assign(:step, "desk_selection")

    reply =
      WhatsApp.buttons_message(
        state.contact_phone,
        "Where would you like to reserve a desk?",
        [
          {"ground_floor", "Ground floor"},
          {"first_floor", "First floor"}
        ]
      )

    {:reply, reply, state}
  end

  # Select desk

  def handle_inbound_message(message, %FlowState{assigns: %{step: "desk_selection"}} = state) do
    {answer, _} = WhatsApp.parse_answer(message)

    state =
      state
      |> assign(:desk_floor, answer)
      |> assign(:step, "confirmation")

    reply =
      WhatsApp.list_message(
        state.contact_phone,
        "What desk would you like to reserve?",
        "Select a desk",
        [
          {"13", "Desk 13", ""},
          {"17", "Desk 17", "with 24 inch monitor"},
          {"21", "Desk 21", "near window"},
          {"25", "Desk 25", ""},
          {"29", "Desk 29", "with dual monitors"},
          {"33", "Desk 33", "quiet area"},
          {"37", "Desk 37", "near entrance"},
          {"41", "Desk 41", "with standing desk"}
        ]
      )

    {:reply, reply, state}
  end

  # Show confirmation

  def handle_inbound_message(message, %FlowState{assigns: %{step: "confirmation"}} = state) do
    {answer, _} = WhatsApp.parse_answer(message)

    state = assign(state, :desk_number, answer)

    {:ok, _reservation} = create_reservation(state)

    reply =
      WhatsApp.text_message(
        state.contact_phone,
        "Desk #{answer} booked for #{state.assigns[:desk_date]}!"
      )

    {:reply_and_end, reply, state}
  end

  def create_reservation(%FlowState{} = state) do
    {reservation_start, reservation_end} =
      case state.assigns[:desk_time] do
        "full_day" ->
          {DateTime.new!(Date.utc_today(), ~T[09:00:00.000], "Etc/UTC"),
           DateTime.new!(Date.utc_today(), ~T[18:00:00.000], "Etc/UTC")}

        "morning" ->
          {DateTime.new!(Date.utc_today(), ~T[09:00:00.000], "Etc/UTC"),
           DateTime.new!(Date.utc_today(), ~T[13:00:00.000], "Etc/UTC")}

        "afternoon" ->
          {DateTime.new!(Date.utc_today(), ~T[13:00:00.000], "Etc/UTC"),
           DateTime.new!(Date.utc_today(), ~T[18:00:00.000], "Etc/UTC")}
      end

    {reservation_start, reservation_end} =
      case state.assigns[:desk_date] do
        "today" ->
          {reservation_start, reservation_end}

        "tomorrow" ->
          {DateTime.shift(reservation_start, day: 1), DateTime.shift(reservation_end, day: 1)}

        "the_day_after_tomorrow" ->
          {DateTime.shift(reservation_start, day: 2), DateTime.shift(reservation_end, day: 2)}
      end

    Reservations.create_reservation(%{
      owner: state.contact_phone,
      resource: :desk,
      start: reservation_start,
      end: reservation_end,
      details: %{
        desk_number: state.assigns[:desk_number],
        desk_floor: state.assigns[:desk_floor]
      }
    })
  end
end
