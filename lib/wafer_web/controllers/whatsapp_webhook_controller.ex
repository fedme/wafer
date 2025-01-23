defmodule WaferWeb.WhatsAppWebhookController do
  @moduledoc """
  Controller that receives webhooks from Meta/WhatsApp.

  Docs: https://developers.facebook.com/docs/whatsapp/cloud-api/guides/set-up-webhooks
  """

  use WaferWeb, :controller

  @doc """
  Action that responds to a verify request from Meta.
  """
  def verify(conn, %{
        "hub.mode" => "subscribe",
        "hub.challenge" => challenge_code,
        "hub.verify_token" => token
      }) do
    if token == verification_token() do
      send_resp(conn, :ok, challenge_code)
    else
      send_resp(conn, :bad_request, "")
    end
  end

  @doc """
  Action that processes a webhook notification from Meta.
  A notification can include new messages, message statuses, contacts, etc.
  """
  def notify(conn, params) do
    if signature_valid?(conn) do
      # Handle the notification asynchronously
      # In production, you may want to use a job queue like Oban
      Task.start(fn -> process_notification(params) end)

      conn
      |> put_status(201)
      |> json(%{})
    else
      send_resp(conn, :unauthorized, "")
    end
  end

  def signature_valid?(conn) do
    payload = WaferWeb.Plugs.CachingBodyReader.get_raw_body(conn)

    computed_signature =
      :crypto.mac(:hmac, :sha256, meta_app_secret(), payload)
      |> Base.encode16(case: :lower)

    [signature_header] = get_req_header(conn, "x-hub-signature-256")
    received_signature = String.replace_prefix(signature_header, "sha256=", "")

    computed_signature == received_signature
  end

  def process_notification(params) do
    params
    |> Map.get("entry", [])
    |> Enum.map(&process_entry/1)
  end

  def process_entry(entry) do
    entry
    |> Map.get("changes", [])
    |> Enum.map(&process_change/1)
  end

  def process_change(change) do
    value = Map.get(change, "value", %{})
    messages = Map.get(value, "messages", [])
    # statuses = Map.get(value, "statuses", [])
    # errors = Map.get(value, "errors", [])
    # contacts = Map.get(value, "contacts", [])

    messages
    |> Enum.map(&IO.inspect/1)
  end

  defp verification_token() do
    Application.get_env(:wafer, __MODULE__)[:verification_token]
  end

  defp meta_app_secret() do
    Application.get_env(:wafer, __MODULE__)[:meta_app_secret]
  end
end
