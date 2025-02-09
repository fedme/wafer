defmodule Wafer.Flow do
  @moduledoc """
  Behavior that defines a flow.

  A flow is a state machine that defines an automated chat
  interaction with a contact.
  """

  alias Wafer.FlowState

  @type message :: map()

  @doc """
  Initializes a Flow
  """
  @callback init(FlowState.t()) :: {:ok, FlowState.t()} | {:error, String.t()}

  @doc """
  Handles an inbound message from a contact
  """
  @callback handle_inbound_message(message(), FlowState.t()) ::
              {:no_reply, FlowState.t()}
              | {:reply, message(), FlowState.t()}
              | {:reply_and_end, message(), FlowState.t()}
              | {:start_flow, String.t(), FlowState.t()}
              | {:error, String.t()}
end
