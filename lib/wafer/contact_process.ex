defmodule Wafer.ContactProcess do
  use GenServer
  alias Wafer.IntentClassifier

  defmodule State do
    defstruct messages: [], current_flow_id: nil
  end

  # Public API
  def start_link(from) do
    GenServer.start_link(__MODULE__, %State{}, name: via_tuple(from))
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
      if wants_to_exit_current_flow?(message) do
        nil
      else
        state.current_flow_id
      end

    new_state = %State{
      state
      | messages: [message | state.messages],
        current_flow_id: current_flow_id
    }

    IO.inspect(new_state, label: "New state")

    {:reply, :ok, new_state}
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

  defp via_tuple(from) do
    {:via, Registry, {Wafer.ContactRegistry, from}}
  end
end
