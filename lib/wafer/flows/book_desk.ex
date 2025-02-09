defmodule Wafer.Flows.BookDesk do
  @moduledoc """
  Flow that allows the user to book a desk at the coworking space.
  """
  @behaviour Wafer.Flow

  alias Wafer.FlowContext
  import Wafer.FlowContext, only: [assign: 3]

  @impl Wafer.Flow
  def init(context) do
    {:ok, assign(context, :step, 0)}
  end

  @impl Wafer.Flow
  def handle_inbound_message(_message, %FlowContext{assigns: %{step: 0}} = context) do
    reply = %{
      "to" => context.contact_phone,
      "type" => "text",
      "text" => %{"body" => "Nice, let's book a desk!"}
    }

    {:reply, reply, assign(context, :step, 1)}
  end

  def handle_inbound_message(_message, %FlowContext{assigns: %{step: 1}} = context) do
    reply = %{
      "to" => context.contact_phone,
      "type" => "text",
      "text" => %{"body" => "Desk booked!"}
    }

    {:reply_and_end, reply, context}
  end
end
