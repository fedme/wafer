defmodule Wafer.Flows do
  @flows [
    %{
      name: "desk_booking_flow",
      description:
        "Call this to start a flow that allows the user to book a desk. No arguments needed, call this as soon as you recognize the intent",
      strict: true,
      parameters: %{
        type: :object,
        properties: %{},
        additionalProperties: false
      },
      module: Wafer.Flows.BookDesk
    },
    %{
      name: "book_meeting_room",
      description: "Book a meeting room at the coworking space",
      strict: true,
      parameters: %{
        type: :object,
        properties: %{},
        additionalProperties: false
      },
      module: Wafer.Flows.BookMeetingRoom
    }
  ]

  def list_flows(), do: @flows

  def get_flow_module(flow_id) do
    Enum.find_value(@flows, &(&1.name == flow_id), & &1.module)
  end

  def flow_exists?(flow_id) do
    Enum.any?(@flows, &(&1.name == flow_id))
  end
end
