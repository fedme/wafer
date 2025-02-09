defmodule Wafer.Flow do
  @moduledoc """
  Behavior that defines a flow.

  A flow is a state machine that defines an automated chat
  interaction with a contact.
  """

  alias Wafer.FlowContext

  @type message :: map()

  @doc """
  Initializes a Flow
  """
  @callback init(FlowContext.t()) :: {:ok, FlowContext.t()} | {:error, String.t()}

  @doc """
  Handles an inbound message from a contact
  """
  @callback handle_inbound_message(message(), FlowContext.t()) ::
              {:no_reply, FlowContext.t()}
              | {:reply, message(), FlowContext.t()}
              | {:reply_and_end, message(), FlowContext.t()}
              | {:start_flow, String.t(), FlowContext.t()}
              | {:error, String.t()}
end
