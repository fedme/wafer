defmodule Wafer.QuitIntentClassifier do
  use GenServer

  @intents [
    "exit",
    "menu",
    "other"
  ]

  # Public API
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def classify(text) do
    GenServer.call(__MODULE__, {:classify, text})
  end

  # GenServer Callbacks
  def init(state) do
    {:ok, state, {:continue, :load_model}}
  end

  def handle_continue(:load_model, state) do
    {:ok, model_info} = Bumblebee.load_model({:hf, "facebook/bart-large-mnli"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "facebook/bart-large-mnli"})
    serving = Bumblebee.Text.zero_shot_classification(model_info, tokenizer, @intents)
    {:noreply, Map.put(state, :serving, serving)}
  end

  def handle_call({:classify, text}, _from, state) do
    result = Nx.Serving.run(state.serving, text)

    %{label: best_category, score: score} =
      Enum.max_by(result.predictions, fn %{score: score} -> score end)

    {:reply, {best_category, score}, state}
  end
end
