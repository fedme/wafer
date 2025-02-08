defmodule Wafer.Flows.Default do
  @moduledoc """
  Default flow, which is a simple AI Assistant that can handle basic inquiries.
  If the assistant recognizes an intent for which we have a predefined flow, it will start that flow.
  """
  @behaviour Wafer.Flow

  @system_prompt """
  You are a support agent for "Milan Coworking Hub", a coworking space located in the heart of Milan.
  The address is Via Dante 14, 20121 Milan, Italy.
  Our space offers both hot desks and dedicated desks, as well as meeting rooms that can be booked by members.
  Our working hours are from 8:00 AM to 8:00 PM, Monday to Friday.
  There is a cafeteria and a restaurant where members can enjoy a meal or a coffee.
  The space also organizes events such as workshops, networking events, and happy hours.
  Please assist our members with any inquiries they may have regarding our services, facilities, and availability.

  The main operations that can be performed are:
  - booking a desk
  - booking a meeting room
  - ordering lunch
  - sign up for an event

  Please reply in the language that the user is using.
  Reply with short messages since your output will be sent over WhatsApp.
  """

  @impl Wafer.Flow
  def handle_inbound_message(message, context) do
    openai_response =
      Req.post!("https://api.openai.com/v1/chat/completions",
        headers: [
          {"Authorization", "Bearer #{System.get_env("OPENAI_API_KEY")}"},
          {"Content-Type", "application/json"}
        ],
        json: %{
          model: "gpt-4o-mini",
          messages: [
            %{"role" => "developer", "content" => @system_prompt},
            # TODO: add full chat history
            %{"role" => "user", "content" => message["text"]["body"]}
          ],
          tools: Enum.map(Wafer.Flows.list_flows(), &%{"type" => "function", "function" => &1})
        }
      )

    case openai_response.body do
      # If the assistant recognized an intent for which we have a predefined flow, start that flow
      %{
        "choices" => [
          %{
            "finish_reason" => "tool_calls",
            "message" => %{"tool_calls" => [%{"function" => %{"name" => function_name}} | _]}
          }
          | _
        ]
      } ->
        {:start_flow, function_name, context}

      %{"choices" => [%{"message" => %{"content" => reply}} | _]} ->
        reply = %{
          "to" => context.contact_phone,
          "type" => "text",
          "text" => %{"body" => reply}
        }

        {:reply, reply, context}
    end
  end
end
