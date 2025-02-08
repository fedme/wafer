defmodule Wafer.Flows.BookDesk do
  @moduledoc """
  Flow that allows the user to book a desk at the coworking space.
  """
  @behaviour Wafer.Flow

  @impl Wafer.Flow
  def handle_inbound_message(_message, context) do
    reply = %{
      "to" => context.contact_phone,
      "type" => "text",
      "text" => %{"body" => "Nice, let's book a desk!"}
    }

    {:reply, reply, context}
  end
end
