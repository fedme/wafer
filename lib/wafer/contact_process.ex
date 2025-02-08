defmodule Wafer.ContactProcess do
  use GenServer
  alias Wafer.IntentClassifier
  alias Wafer.FlowContext
  alias Wafer.Flows

  require Logger

  defmodule State do
    defstruct current_flow_id: nil, flow_context: %FlowContext{}
  end

  # Public API
  def start_link(from) do
    GenServer.start_link(
      __MODULE__,
      %State{flow_context: %FlowContext{contact_phone: from}},
      name: via_tuple(from)
    )
  end

  def handle_inbound_message(from, message) do
    GenServer.call(via_tuple(from), {:handle_inbound_message, message})
  end

  # GenServer Callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_call({:handle_inbound_message, message}, _from, state) do
    current_flow_id =
      if is_nil(state.current_flow_id) || wants_to_exit_current_flow?(message) do
        nil
      else
        state.current_flow_id
      end

    state = %State{
      state
      | current_flow_id: current_flow_id,
        flow_context: %FlowContext{
          state.flow_context
          | messages: [message | state.flow_context.messages]
        }
    }

    state = run_current_flow(message, state)

    IO.inspect(state, label: "New state")

    {:reply, :ok, state}
  end

  # Internal functions
  def wants_to_exit_current_flow?(%{"type" => "text", "text" => %{"body" => message}})
      when message in ["exit", "quit", "stop", "cancel", "menu"] do
    true
  end

  def wants_to_exit_current_flow?(%{"type" => "text", "text" => %{"body" => text}}) do
    {intent, score} = IntentClassifier.classify(text)
    IO.inspect({intent, score}, label: "Intent for #{text}")
    intent in ["exit", "menu"] and score > 0.55
  end

  def wants_to_exit_current_flow?(_message), do: false

  def run_current_flow(message, state) do
    result =
      case state.current_flow_id do
        nil ->
          Wafer.Flows.Default.handle_inbound_message(message, state.flow_context)

        flow_id ->
          run_flow(flow_id, message, state)
      end

    case result do
      {:no_reply, flow_context} ->
        %State{state | flow_context: flow_context}

      {:reply, reply, flow_context} ->
        Wafer.WhatsApp.send_message(reply)
        %State{state | flow_context: flow_context}

      {:start_flow, flow_id, flow_context} ->
        if Flows.flow_exists?(flow_id) do
          run_current_flow(message, %State{
            state
            | current_flow_id: flow_id,
              flow_context: flow_context
          })
        else
          Logger.error("Flow #{flow_id} not found")
          %State{state | flow_context: flow_context}
        end

      {:error, reason} ->
        Logger.error("Error: #{inspect(reason)}")
        state
    end
  end

  def run_flow(flow_id, message, state) do
    flow_module = Flows.get_flow_module(flow_id)

    if Code.ensure_loaded?(flow_module) do
      flow_module.handle_inbound_message(message, state.flow_context)
    else
      Logger.error("Flow module #{flow_module} not found")
    end
  end

  defp via_tuple(from) do
    {:via, Registry, {Wafer.ContactRegistry, from}}
  end
end
