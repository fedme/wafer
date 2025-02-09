defmodule Wafer.Flows.BookDesk do
  @moduledoc """
  Flow that allows the user to book a desk at the coworking space.
  """
  @behaviour Wafer.Flow

  alias Wafer.FlowState
  import Wafer.FlowState, only: [assign: 3]
  alias Wafer.WhatsApp

  @impl Wafer.Flow
  def init(state) do
    {:ok, assign(state, :step, "date_selection")}
  end

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

  def handle_inbound_message(message, %FlowState{assigns: %{step: "confirmation"}} = state) do
    {answer, _} = WhatsApp.parse_answer(message)

    state = assign(state, :desk_number, answer)

    reply =
      WhatsApp.text_message(
        state.contact_phone,
        "Desk #{answer} booked for #{state.assigns[:desk_date]}!"
      )

    {:reply_and_end, reply, state}
  end
end
