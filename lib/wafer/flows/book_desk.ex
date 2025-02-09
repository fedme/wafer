defmodule Wafer.Flows.BookDesk do
  @moduledoc """
  Flow that allows the user to book a desk at the coworking space.
  """
  @behaviour Wafer.Flow

  alias Wafer.FlowState
  import Wafer.FlowState, only: [assign: 3]

  @impl Wafer.Flow
  def init(state) do
    {:ok, assign(state, :step, 0)}
  end

  @impl Wafer.Flow
  def handle_inbound_message(_message, %FlowState{assigns: %{step: 0}} = state) do
    reply = %{
      "to" => state.contact_phone,
      "type" => "text",
      "text" => %{"body" => "Nice, let's book a desk!"}
    }

    {:reply, reply, assign(state, :step, 1)}
  end

  def handle_inbound_message(_message, %FlowState{assigns: %{step: 1}} = state) do
    reply = %{
      "to" => state.contact_phone,
      "type" => "text",
      "text" => %{"body" => "Desk booked!"}
    }

    {:reply_and_end, reply, state}
  end
end
