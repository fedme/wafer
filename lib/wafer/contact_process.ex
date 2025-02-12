defmodule Wafer.ContactProcess do
  use GenServer
  alias Wafer.QuitIntentClassifier
  alias Wafer.FlowState
  alias Wafer.Flows

  require Logger

  defmodule State do
    defstruct current_flow_id: nil, flow_state: %FlowState{}, last_inbound_timestamp: 0
  end

  # Public API
  def start_link(from) do
    GenServer.start_link(
      __MODULE__,
      %State{flow_state: %FlowState{contact_phone: from}},
      name: via_tuple(from)
    )
  end

  def handle_inbound_message(from, message) do
    GenServer.call(via_tuple(from), {:handle_inbound_message, message}, 20_000)
  end

  # GenServer Callbacks
  def init(state) do
    Process.send_after(self(), :check_timeout, 60 * 1000)
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
        last_inbound_timestamp: DateTime.to_unix(DateTime.utc_now(), :second),
        flow_state: FlowState.append_message(state.flow_state, message)
    }

    state = run_current_flow(message, state)

    {:reply, :ok, state}
  end

  def handle_info(:check_timeout, state) do
    if DateTime.to_unix(DateTime.utc_now(), :second) - state.last_inbound_timestamp > 5 * 60 do
      Logger.info(
        "Contact process for #{state.flow_state.contact_phone} terminating for inactivity."
      )

      {:stop, :normal, state}
    else
      Process.send_after(self(), :check_timeout, 60 * 1000)
      {:noreply, state}
    end
  end

  # Internal functions
  def wants_to_exit_current_flow?(%{"type" => "text", "text" => %{"body" => message}})
      when message in ["exit", "quit", "stop", "cancel", "menu"] do
    true
  end

  def wants_to_exit_current_flow?(%{"type" => "text", "text" => %{"body" => text}}) do
    {intent, score} = QuitIntentClassifier.classify(text)
    IO.inspect({intent, score}, label: "Intent for #{text}")
    intent in ["exit", "menu"] and score > 0.55
  end

  def wants_to_exit_current_flow?(_message), do: false

  def run_current_flow(message, state) do
    result =
      case state.current_flow_id do
        nil ->
          Wafer.Flows.Default.handle_inbound_message(message, state.flow_state)

        flow_id ->
          run_flow(flow_id, message, state)
      end

    case result do
      {:no_reply, flow_state} ->
        %State{state | flow_state: flow_state}

      {:reply, reply, flow_state} ->
        Wafer.WhatsApp.send_message(reply)
        %State{state | flow_state: FlowState.append_message(flow_state, reply)}

      {:reply_and_end, reply, flow_state} ->
        Wafer.WhatsApp.send_message(reply)

        %State{
          state
          | current_flow_id: nil,
            flow_state: FlowState.append_message(flow_state, reply)
        }

      {:start_flow, flow_id, flow_state} ->
        if Flows.flow_exists?(flow_id) do
          state = %State{state | current_flow_id: flow_id, flow_state: flow_state}
          {:ok, flow_state} = init_flow(flow_id, state)
          state = %State{state | flow_state: flow_state}
          run_current_flow(message, state)
        else
          Logger.error("Flow #{flow_id} not found")
          %State{state | flow_state: flow_state}
        end

      {:error, reason} ->
        Logger.error("Error: #{inspect(reason)}")
        state
    end
  end

  def init_flow(flow_id, state) do
    flow_module = Flows.get_flow_module(flow_id)

    if Code.ensure_loaded?(flow_module) do
      flow_module.init(state.flow_state)
    else
      Logger.error("Flow module #{flow_module} not found")
    end
  end

  def run_flow(flow_id, message, state) do
    flow_module = Flows.get_flow_module(flow_id)

    if Code.ensure_loaded?(flow_module) do
      flow_module.handle_inbound_message(message, state.flow_state)
    else
      Logger.error("Flow module #{flow_module} not found")
    end
  end

  defp via_tuple(from) do
    {:via, Registry, {Wafer.ContactRegistry, from}}
  end
end
