defmodule Wafer.WhatsApp do
  def send_message(message) do
    response =
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

    IO.inspect(response.body)
  end

  defp token() do
    Application.get_env(:wafer, __MODULE__)[:token]
  end

  defp business_number_id() do
    Application.get_env(:wafer, __MODULE__)[:business_number_id]
  end
end
