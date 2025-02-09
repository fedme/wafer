defmodule Wafer.OpenAi do
  def chat_completion(messages, tools) do
    Req.post!("https://api.openai.com/v1/chat/completions",
      receive_timeout: 20_000,
      headers: [
        {"Authorization", "Bearer #{System.get_env("OPENAI_API_KEY")}"},
        {"Content-Type", "application/json"}
      ],
      json: %{
        model: "gpt-4o-mini",
        messages: messages,
        tools: tools
      }
    )
  end

  def whatsapp_messages_to_openai_messages(messages) do
    messages
    |> Enum.map(&whatsapp_message_to_openai_message/1)
    |> Enum.reject(&is_nil/1)
  end

  def whatsapp_message_to_openai_message(
        %{"type" => "text", "text" => %{"body" => body}} = message
      ) do
    %{role: role(message), content: body}
  end

  def whatsapp_message_to_openai_message(%{
        "to" => _to,
        "type" => "interactive",
        "interactive" => %{
          "type" => "button",
          "body" => %{"text" => body},
          "action" => %{"buttons" => buttons}
        }
      }) do
    %{
      role: "assistant",
      content: "#{body} #{Enum.map_join(buttons, " | ", &get_in(&1, ["reply", "title"]))}"
    }
  end

  def whatsapp_message_to_openai_message(%{
        "to" => _to,
        "type" => "interactive",
        "interactive" => %{
          "type" => "list",
          "body" => %{"text" => body},
          "action" => %{"sections" => sections}
        }
      }) do
    options =
      Enum.flat_map(sections, fn section ->
        Enum.map(section["rows"], fn row -> row["title"] end)
      end)

    %{
      role: "assistant",
      content: "#{body} #{Enum.join(options, " | ")}"
    }
  end

  def whatsapp_message_to_openai_message(%{
        "from" => _from,
        "type" => "button",
        "button" => %{"text" => text}
      }) do
    %{role: "user", content: text}
  end

  def whatsapp_message_to_openai_message(%{
        "from" => _from,
        "type" => "interactive",
        "interactive" => %{"list_reply" => %{"title" => text}}
      }) do
    %{role: "user", content: text}
  end

  def whatsapp_message_to_openai_message(%{
        "from" => _from,
        "type" => "interactive",
        "interactive" => %{"button_reply" => %{"title" => text}}
      }) do
    %{role: "user", content: text}
  end

  def whatsapp_message_to_openai_message(%{
        "from" => _from,
        "type" => "reaction",
        "reaction" => %{"emoji" => emoji}
      }) do
    %{role: "user", content: emoji}
  end

  def whatsapp_message_to_openai_message(_message), do: nil

  def role(message) do
    if Map.has_key?(message, "from") do
      "user"
    else
      "assistant"
    end
  end
end
