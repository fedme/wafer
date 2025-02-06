defmodule Wafer.FlowContext do
  @type t :: %__MODULE__{
          messages: [String.t()],
          contact_phone: String.t() | nil,
          private: map()
        }

  defstruct messages: [], contact_phone: nil, private: %{}
end
