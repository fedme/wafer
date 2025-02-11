defmodule Wafer.Flows do
  @flows [
    %{
      name: "desk_booking_flow",
      description:
        "Call this to start a flow that allows the user to book a desk. No arguments needed, call this as soon as you recognize the intent to book a desk",
      strict: true,
      parameters: %{
        type: :object,
        properties: %{},
        additionalProperties: false
      },
      module: Wafer.Flows.BookDesk
    },
    %{
      name: "meeting_room_booking_flow",
      description:
        "Call this to start a flow that allows the user to book a meeting room. No arguments needed, call this as soon as you recognize the intent to book a meeting room",
      strict: true,
      parameters: %{
        type: :object,
        properties: %{},
        additionalProperties: false
      },
      module: Wafer.Flows.BookMeetingRoom
    },
    %{
      name: "list_reservations_flow",
      description:
        "Call this to start a flow that lists the user's reservations of desks and meeting rooms. No arguments needed, call this as soon as you recognize the intent to list reservations",
      strict: true,
      parameters: %{
        type: :object,
        properties: %{},
        additionalProperties: false
      },
      module: Wafer.Flows.ListReservations
    }
  ]

  def list_flows(), do: @flows

  def get_flow_module(flow_id) do
    Enum.find_value(@flows, fn x -> if x.name == flow_id, do: x.module end)
    |> IO.inspect(label: "Flow module")
  end

  def flow_exists?(flow_id) do
    Enum.any?(@flows, &(&1.name == flow_id))
  end
end
