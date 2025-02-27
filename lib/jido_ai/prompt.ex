defmodule Jido.AI.Prompt do
  @moduledoc ~S"""
  A behavior for modules that can generate contextual prompts.

  This behavior is specifically for function-based prompt generation, where
  prompts are generated based on context parameters. For struct-based prompt
  generation, use the Jido.AI.Promptable protocol instead.

  ## Examples

      defmodule MyApp.GreetingPrompt do
        use Jido.AI.Prompt

        @impl true
        def prompt(%{name: name, style: style}) do
          case style do
            :formal -> "Greetings, #{name}."
            :casual -> "Hey #{name}!"
            _ -> "Hi #{name}!"
          end
        end

        def prompt(%{name: name}) do
          "Hi #{name}!"
        end

        def prompt(_) do
          "Hello there!"
        end
      end

      # Use it with context
      MyApp.GreetingPrompt.prompt(%{name: "Alice", style: :formal})
      #=> "Greetings, Alice."
  """

  @doc """
  Generates a prompt string based on the given context.

  The context is a map of parameters that can be used to customize the prompt.
  """
  @callback prompt(context :: map()) :: String.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Jido.AI.Prompt

      # Simple behavior implementation
      def prompt(context)
      defoverridable prompt: 1
    end
  end

  @doc """
  Creates a new prompt module from a string. Raises if invalid.

  ## Examples

      iex> prompt = Jido.AI.Prompt.new!("Hello, I am an AI assistant")
      iex> prompt.prompt(%{})
      "Hello, I am an AI assistant"
  """
  def new!(content) when is_binary(content) do
    # Create a new anonymous module that implements the Prompt behavior
    module = Module.concat(Jido.AI.Prompt, "Prompt#{:erlang.unique_integer([:positive])}")

    Module.create(
      module,
      quote do
        use Jido.AI.Prompt
        @impl true
        def prompt(_context), do: unquote(content)
      end,
      Macro.Env.location(__ENV__)
    )

    module
  end

  @doc """
  Validates a prompt value for NimbleOptions.

  Accepts either a string or a module that implements the Jido.AI.Prompt behavior.

  ## Returns

  * `{:ok, prompt}` - The prompt is valid.
  * `{:error, reason}` - The prompt is invalid.
  """
  @spec validate_prompt(term()) :: {:ok, term()} | {:error, String.t()}
  def validate_prompt(prompt) when is_binary(prompt) do
    {:ok, new!(prompt)}
  end

  def validate_prompt(prompt) when is_atom(prompt) do
    if Code.ensure_loaded?(prompt) and function_exported?(prompt, :prompt, 1) do
      {:ok, prompt}
    else
      {:error,
       "Expected a module that implements the Jido.AI.Prompt behavior, got: #{inspect(prompt)}"}
    end
  end

  def validate_prompt(other) do
    {:error,
     "Expected a string or a module that implements the Jido.AI.Prompt behavior, got: #{inspect(other)}"}
  end

  @doc """
  Composes prompts from multiple promptable modules or structs.

  Each item in the list can be either:
  - A module that implements the `Jido.AI.Prompt` behavior
  - A struct that implements the `Jido.AI.Promptable` protocol

  The context is passed to each module's `prompt/1` function or merged with
  each struct before converting it via the protocol.

  Returns a string with all the prompts joined by the given separator.

  ## Examples

      # Compose prompts from behavior modules
      Jido.AI.Prompt.compose([MyApp.GreetingPrompt, MyApp.TaskPrompt], %{
        name: "Charlie",
        style: :formal
      })

      # Compose prompts from structs
      Jido.AI.Prompt.compose([%User{name: "Alice"}, %Task{title: "Learn Elixir"}])
  """
  @spec compose(list(), map(), String.t()) :: String.t()
  def compose(items, context \\ %{}, separator \\ "\n\n") do
    items
    |> Enum.map(fn
      module when is_atom(module) ->
        # If it's a module, call its prompt function
        if function_exported?(module, :prompt, 1) do
          module.prompt(context)
        else
          raise ArgumentError, "Module #{inspect(module)} does not implement prompt/1"
        end

      %{__struct__: _} = struct ->
        # If it's a struct, try to convert it via the protocol
        if Map.keys(context) == [] do
          Jido.AI.Promptable.to_prompt(struct)
        else
          # Merge the context with the struct
          struct
          |> Map.from_struct()
          |> Map.merge(context)
          |> then(&struct(struct.__struct__, &1))
          |> Jido.AI.Promptable.to_prompt()
        end

      other ->
        raise ArgumentError, "Expected a module or struct, got: #{inspect(other)}"
    end)
    |> Enum.join(separator)
  end
end
