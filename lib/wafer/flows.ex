defmodule Wafer.Flows do
  @flows [
    %{
      name: "book_desk",
      description: "Book a desk at the coworking space",
      parameters: %{},
      module: Wafer.Flows.BookDesk
    },
    %{
      name: "book_meeting_room",
      description: "Book a meeting room at the coworking space",
      parameters: %{},
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
