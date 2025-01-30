defmodule Wafer.ContactRouter do
  alias Wafer.ContactProcess

  def handle_inbound_message(%{"from" => from} = message) do
    case Registry.lookup(Wafer.ContactRegistry, from) do
      [] ->
        # Process not found, start a new Contact process
        {:ok, pid} =
          DynamicSupervisor.start_child(Wafer.ContactSupervisor, {ContactProcess, from})

        IO.inspect(pid, label: "Started new Contact process")

      [{_pid, _value}] ->
        # Process already exists
        nil
    end

    ContactProcess.handle_inbound_message(from, message)
  end
end
