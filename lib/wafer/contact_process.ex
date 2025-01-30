defmodule Wafer.ContactProcess do
  use GenServer

  # Public API
  def start_link(from) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(from))
  end

  def handle_inbound_message(from, message) do
    GenServer.call(via_tuple(from), {:handle_inbound_message, message})
  end

  # GenServer Callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_call({:handle_inbound_message, message}, _from, state) do
    new_state = [message | state]
    IO.inspect(new_state, label: "New state")
    {:reply, :ok, new_state}
  end

  defp via_tuple(from) do
    {:via, Registry, {Wafer.ContactRegistry, from}}
  end
end
