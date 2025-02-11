defmodule Wafer.Flows.BookMeetingRoom do
  @moduledoc """
  Flow that allows the user to book a meeting room at the coworking space.
  """
  @behaviour Wafer.Flow

  alias Wafer.FlowState
  import Wafer.FlowState, only: [assign: 3]
  alias Wafer.WhatsApp

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
        "When do you need the meeting room?",
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
      |> assign(:room_date, answer)
      |> assign(:step, "room_selection")

    reply =
      WhatsApp.list_message(
        state.contact_phone,
        "What time do you need the room",
        "Select a time",
        [
          {"9:00", "9:00", ""},
          {"10:00", "10:00", ""},
          {"11:00", "11:00", ""},
          {"12:00", "12:00", ""},
          {"13:00", "13:00", ""},
          {"14:00", "14:00", ""},
          {"15:00", "15:00", ""},
          {"16:00", "16:00", ""},
          {"17:00", "17:00", ""}
        ]
      )

    {:reply, reply, state}
  end

  # Select floor

  # Select room

  def handle_inbound_message(message, %FlowState{assigns: %{step: "room_selection"}} = state) do
    {answer, _} = WhatsApp.parse_answer(message)

    state =
      state
      |> assign(:room_time, answer)
      |> assign(:step, "confirmation")

    reply =
      WhatsApp.list_message(
        state.contact_phone,
        "What meeting room would you like to reserve?",
        "Select a room",
        [
          {"4", "Meeting room 4", "with conference table"},
          {"5", "Meeting room 5", "with whiteboard"},
          {"6", "Meeting room 6", "with projector"},
          {"7", "Meeting room 7", ""},
          {"8", "Meeting room 8", ""},
          {"9", "Meeting room 9", ""}
        ]
      )

    {:reply, reply, state}
  end

  # Show confirmation

  def handle_inbound_message(message, %FlowState{assigns: %{step: "confirmation"}} = state) do
    {answer, _} = WhatsApp.parse_answer(message)

    state = assign(state, :desk_number, answer)

    reply =
      WhatsApp.text_message(
        state.contact_phone,
        "Meeting room #{answer} booked for #{state.assigns[:room_date]} at #{state.assigns[:room_time]}!"
      )

    {:reply_and_end, reply, state}
  end
end
