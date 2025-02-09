defmodule Wafer.FlowState do
  @type t :: %__MODULE__{
          messages: [String.t()],
          contact_phone: String.t() | nil,
          assigns: map()
        }

  defstruct messages: [], contact_phone: nil, assigns: %{}

  def assign(%__MODULE__{} = state, key, value) do
    %__MODULE__{state | assigns: Map.put(state.assigns, key, value)}
  end
end
