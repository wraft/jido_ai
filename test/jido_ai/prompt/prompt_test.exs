defmodule JidoTest.AI.PromptTest do
  use ExUnit.Case, async: true
  doctest Jido.AI.Prompt
  @moduletag :capture_log
  alias JidoTest.AI.Examples.TestStructs.{User, Task, Profile}

  # Example module using the Prompt behavior for function-based prompts
  defmodule GreetingPrompt do
    use Jido.AI.Prompt

    @impl true
    def prompt(context) do
      name = Map.get(context, :name, "friend")
      style = Map.get(context, :style, :casual)

      case style do
        :formal -> "Greetings, #{name}."
        _ -> "Hey #{name}!"
      end
    end
  end

  # Example module using the Prompt behavior with template-like functionality
  defmodule TaskPrompt do
    use Jido.AI.Prompt

    @impl true
    def prompt(context) do
      task = Map.get(context, :task, "something")
      status = Map.get(context, :status, "pending")
      "Task '#{task}' is #{status}"
    end
  end

  # Example struct for testing protocol-based prompts
  defmodule TestStruct do
    defstruct [:message]
  end

  # Implement protocol for TestStruct
  defimpl Jido.AI.Promptable, for: TestStruct do
    def to_prompt(%{message: message}) when not is_nil(message) do
      "Test message: #{message}"
    end

    def to_prompt(_) do
      "Empty test message"
    end
  end

  describe "behavior implementation" do
    test "implements basic greeting prompt" do
      assert GreetingPrompt.prompt(%{name: "Alice"}) == "Hey Alice!"
      assert GreetingPrompt.prompt(%{name: "Bob", style: :formal}) == "Greetings, Bob."
    end

    test "implements task prompt" do
      assert TaskPrompt.prompt(%{task: "Write tests", status: "in progress"}) ==
               "Task 'Write tests' is in progress"
    end

    test "handles missing context values with defaults" do
      assert GreetingPrompt.prompt(%{}) == "Hey friend!"
      assert TaskPrompt.prompt(%{}) == "Task 'something' is pending"
    end
  end

  describe "compose/3" do
    setup do
      user = %User{name: "Alice", age: 30}
      task = %Task{title: "Write tests", status: "in progress", due_date: "2024-03-20"}
      profile = %Profile{bio: "Developer", skills: ["Elixir", "Testing"]}
      test_struct = %TestStruct{message: "Hello"}

      {:ok, user: user, task: task, profile: profile, test_struct: test_struct}
    end

    test "composes prompts from behavior modules" do
      modules = [GreetingPrompt, TaskPrompt]
      context = %{name: "Alice", style: :formal, task: "Testing", status: "active"}

      result = Jido.AI.Prompt.compose(modules, context)
      assert result =~ "Greetings, Alice."
      assert result =~ "Task 'Testing' is active"
    end

    test "composes prompts from structs", %{user: user, task: task, profile: profile} do
      result = Jido.AI.Prompt.compose([user, task, profile])

      assert result =~ "User Alice is 30 years old"
      assert result =~ "Task 'Write tests' is in progress"
      assert result =~ "Profile: Developer"
      assert result =~ "Skills: Elixir, Testing"
    end

    test "composes prompts from both behaviors and structs", %{test_struct: test_struct} do
      result =
        Jido.AI.Prompt.compose(
          [GreetingPrompt, test_struct],
          %{name: "Alice", style: :formal}
        )

      assert result =~ "Greetings, Alice"
      assert result =~ "Test message: Hello"
    end

    test "composes prompts with custom separator" do
      modules = [GreetingPrompt, TaskPrompt]
      context = %{name: "Alice", task: "Testing"}
      separator = " | "

      result = Jido.AI.Prompt.compose(modules, context, separator)
      assert result == "Hey Alice! | Task 'Testing' is pending"
    end

    test "merges context with struct data", %{user: user} do
      result = Jido.AI.Prompt.compose([user], %{age: 35})
      assert result == "User Alice is 35 years old"
    end
  end

  describe "error handling" do
    test "raises for invalid module in compose" do
      assert_raise ArgumentError, ~r/Expected a module or struct/, fn ->
        Jido.AI.Prompt.compose(["not a module"], %{})
      end
    end

    test "raises for module without prompt/1" do
      defmodule InvalidModule do
        # No prompt/1 implementation
      end

      assert_raise ArgumentError, ~r/does not implement prompt\/1/, fn ->
        Jido.AI.Prompt.compose([InvalidModule], %{})
      end
    end

    test "raises for invalid map in compose" do
      assert_raise ArgumentError, ~r/Expected a module or struct/, fn ->
        Jido.AI.Prompt.compose([%{not: "a struct"}], %{})
      end
    end
  end
end
