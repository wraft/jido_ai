defmodule Jido.AI do
  @moduledoc """
  High-level API for accessing AI provider keys.
  """

  alias Jido.AI.Keyring

  @ai_opts_key :ai
  @ai_opts_schema NimbleOptions.new!(
                    model: [
                      type: {:custom, Jido.AI.Model, :validate_model_opts, []},
                      required: true,
                      doc: "The AI model to use"
                    ],
                    prompt: [
                      type: {:custom, Jido.AI.Prompt, :validate_prompt, []},
                      default: "You are a helpful assistant",
                      doc: "The default instructions to follow (string or Jido.AI.Prompt module)"
                    ],
                    schema: [
                      type: :keyword_list,
                      default: [],
                      doc: "A NimbleOptions schema to validate the AI response"
                    ],
                    chat_action: [
                      type: {:custom, Jido.Util, :validate_actions, []},
                      default: Jido.AI.Actions.OpenaiEx.ChatCompletion,
                      doc: "The chat action to use"
                    ],
                    tool_action: [
                      type: {:custom, Jido.Util, :validate_actions, []},
                      default: Jido.AI.Actions.Langchain.ToolCompletion,
                      doc: "The default tool action to use"
                    ],
                    tools: [
                      type: {:custom, Jido.Util, :validate_actions, []},
                      default: [],
                      doc: "The tools to use"
                    ]
                  )

  @spec validate_opts(keyword()) :: {:ok, keyword()} | {:error, String.t()}
  def validate_opts(opts) do
    # Get AI opts if they exist under the ai key, otherwise use full opts
    ai_opts =
      if Keyword.has_key?(opts, @ai_opts_key) do
        Keyword.get(opts, @ai_opts_key)
      else
        opts
      end

    case NimbleOptions.validate(ai_opts, @ai_opts_schema) do
      {:ok, validated_opts} ->
        {:ok, validated_opts}

      {:error, errors} ->
        {:error, errors}
    end
  end

  defdelegate get_key(provider), to: Keyring
  defdelegate set_session_key(provider, key), to: Keyring
  defdelegate get_session_key(provider), to: Keyring
  defdelegate clear_session_key(provider), to: Keyring
  defdelegate clear_all_session_keys, to: Keyring

  def prompt(items, context \\ %{}, separator \\ "\n\n") do
    Jido.AI.Prompt.compose(items, context, separator)
  end
end
