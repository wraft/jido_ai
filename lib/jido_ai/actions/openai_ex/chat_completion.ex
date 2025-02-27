defmodule Jido.AI.Actions.OpenaiEx.ChatCompletion do
  use Jido.Action,
    name: "openai_ex_chat_completion",
    description: "Chat completion using OpenAI Ex"

  require Logger

  def run(params, context) do
    Logger.info("Running OpenAI Ex chat completion with params: #{inspect(params)}")
    Logger.info("Context: #{inspect(context)}")
    ai = get_in(context, [:state, :ai])
    Logger.info("AI: #{inspect(ai)}")

    api_key = Jido.AI.Keyring.get(:openrouter_api_key)

    chat_req =
      OpenaiEx.Chat.Completions.new(
        model: "anthropic/claude-3.5-haiku",
        messages: [
          OpenaiEx.ChatMessage.user("What is the capital of France?")
        ]
      )

    # IO.inspect(chat_req)

    {:ok, response} =
      OpenaiEx.new(api_key)
      |> OpenaiEx.with_base_url(Jido.AI.Provider.OpenRouter.base_url())
      # |> OpenaiEx.with_additional_headers(Jido.AI.Provider.OpenRouter.request_headers([]))
      |> OpenaiEx.Chat.Completions.create(chat_req)

    {:ok, response}
  end
end
