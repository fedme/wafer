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
    Enum.map(messages, &whatsapp_message_to_openai_message/1)
  end

  def whatsapp_message_to_openai_message(
        %{"type" => "text", "text" => %{"body" => body}} = message
      ) do
    %{role: role(message), content: body}
  end

  def role(message) do
    if Map.has_key?(message, "from") do
      "user"
    else
      "assistant"
    end
  end
end
