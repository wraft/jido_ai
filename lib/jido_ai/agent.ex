defmodule Jido.AI.Agent do
  use Jido.Agent,
    name: "jido_ai_agent",
    description: "General purpose AI agent powered by Jido",
    category: "AI Agents",
    tags: ["AI", "Agent"],
    vsn: "0.1.0"

  def start_link(opts) do
    validated_ai_opts = Jido.AI.validate_opts(opts)
    id = Keyword.get(opts, :id, Jido.Util.generate_id())

    chat_action =
      Keyword.get(validated_ai_opts, :chat_action, Jido.AI.Actions.OpenaiEx.ChatCompletion)

    tool_action =
      Keyword.get(validated_ai_opts, :tool_action, Jido.AI.Actions.Langchain.ToolCompletion)

    # Create the Agent, add the Tools as valid Actions
    agent =
      Jido.AI.Agent.new(
        id: id,
        initial_state: %{
          ai: validated_ai_opts
        }
      )

    tools = Keyword.get(validated_ai_opts, :tools, [])
    {:ok, agent} = Jido.AI.Agent.register_action(agent, tools ++ [chat_action, tool_action])

    Jido.Agent.Server.start_link(
      id: id,
      agent: agent,
      initial_state: %{
        ai: validated_ai_opts
      },
      dispatch: [
        {:logger, level: :info}
      ],
      mode: :auto,
      routes: [
        {"jido.ai.chat.response",
         %Instruction{
           action: chat_action,
           opts: [timeout: 29_000]
         }},
        {"jido.ai.tool.response",
         %Instruction{
           action: tool_action,
           opts: [timeout: 29_000]
         }}
      ]
    )
  end

  def chat_response(pid, message, opts \\ []) do
    _personality = Keyword.get(opts, :personality, "You are a helpful assistant")
    _prompt = Keyword.get(opts, :prompt, "")

    {:ok, signal} =
      Jido.Signal.new(%{
        type: "jido.ai.chat.response",
        data: %{
          prompt: "",
          personality: "You are a helpful assistant",
          history: [],
          message: message
        }
      })

    call(pid, signal)
  end

  def tool_response(pid, message, opts \\ []) do
    _personality = Keyword.get(opts, :personality, "You are a helpful assistant")
    _prompt = Keyword.get(opts, :prompt, "")

    {:ok, signal} =
      Jido.Signal.new(%{
        type: "jido.ai.tool.response",
        data: %{
          prompt: "",
          personality: "You are a helpful assistant",
          history: [],
          message: message
        }
      })

    call(pid, signal)
  end
end
