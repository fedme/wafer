defmodule Wafer.WhatsApp do
  def send_message(message) do
    Req.post!(
      "https://graph.facebook.com/v19.0/#{business_number_id()}/messages",
      headers: [
        {"Authorization", "Bearer #{token()}"},
        {"Content-Type", "application/json"}
      ],
      json:
        Map.merge(
          %{
            "messaging_product" => "whatsapp",
            "recipient_type" => "individual"
          },
          message
        )
    )
  end

  def text_message(to, body) do
    %{
      "to" => to,
      "type" => "text",
      "text" => %{"body" => body}
    }
  end

  def buttons_message(to, body, buttons) do
    %{
      "to" => to,
      "type" => "interactive",
      "interactive" => %{
        "type" => "button",
        "body" => %{"text" => body},
        "action" => %{
          "buttons" =>
            buttons
            |> Enum.take(3)
            |> Enum.map(fn {id, title} ->
              %{
                "type" => "reply",
                "reply" => %{
                  "id" => id,
                  "title" => title
                }
              }
            end)
        }
      }
    }
  end

  def list_message(to, body, button_label, options) do
    %{
      "to" => to,
      "type" => "interactive",
      "interactive" => %{
        "type" => "list",
        "body" => %{"text" => body},
        "action" => %{
          "button" => button_label,
          "sections" => [
            %{
              "title" => "",
              "rows" =>
                Enum.map(options, fn {id, title, description} ->
                  %{
                    "id" => id,
                    "title" => title,
                    "description" => description
                  }
                end)
            }
          ]
        }
      }
    }
  end

  def parse_answer(%{
        "from" => _from,
        "type" => "text",
        "text" => %{"body" => text}
      }) do
    {nil, text}
  end

  def parse_answer(%{
        "from" => _from,
        "type" => "button",
        "button" => %{"id" => id, "text" => text}
      }) do
    {id, text}
  end

  def parse_answer(%{
        "from" => _from,
        "type" => "interactive",
        "interactive" => %{"list_reply" => %{"id" => id, "title" => text}}
      }) do
    {id, text}
  end

  def parse_answer(%{
        "from" => _from,
        "type" => "interactive",
        "interactive" => %{"button_reply" => %{"id" => id, "title" => text}}
      }) do
    {id, text}
  end

  defp token() do
    Application.get_env(:wafer, __MODULE__)[:token]
  end

  defp business_number_id() do
    Application.get_env(:wafer, __MODULE__)[:business_number_id]
  end
end
