defmodule Wafer.Flows do
  @flows [
    %{
      "name" => "book_desk",
      "description" => "Book a desk at the coworking space",
      "parameters" => %{}
    },
    %{
      "name" => "book_meeting_room",
      "description" => "Book a meeting room at the coworking space",
      "parameters" => %{}
    }
  ]

  def list_flows(), do: @flows
end
