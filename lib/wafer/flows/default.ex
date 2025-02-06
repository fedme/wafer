defmodule Wafer.Flows.Default do
  @behaviour Wafer.Flow

  @impl Wafer.Flow
  def handle_inbound_message(_message, context) do
    reply = %{
      "to" => context.contact_phone,
      "type" => "text",
      "text" => %{"body" => "This is the default flow responding"}
    }

    {:reply, reply, context}
  end
end
