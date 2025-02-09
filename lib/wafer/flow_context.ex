defmodule Wafer.FlowContext do
  @type t :: %__MODULE__{
          messages: [String.t()],
          contact_phone: String.t() | nil,
          assigns: map()
        }

  defstruct messages: [], contact_phone: nil, assigns: %{}

  def assign(%__MODULE__{} = context, key, value) do
    %__MODULE__{context | assigns: Map.put(context.assigns, key, value)}
  end
end
