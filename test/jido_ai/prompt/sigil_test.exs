defmodule JidoTest.AI.Prompt.SigilTest do
  use ExUnit.Case, async: true
  doctest Jido.AI.Prompt.Sigil
  @moduletag :capture_log
  import Jido.AI.Prompt.Sigil

  describe "sigil_AI/2" do
    test "creates a template from a simple string" do
      template = ~AI"Hello <%= @name %>"
      assert template.text == "Hello <%= @name %>"
      assert template.role == :user
      assert template.engine == :eex
    end

    test "creates a template with heredoc syntax" do
      template = ~AI"""
      Hello <%= @name %>
      You are <%= @age %> years old
      """

      assert String.trim(template.text) == "Hello <%= @name %>\nYou are <%= @age %> years old"
      assert template.role == :user
    end

    test "ignores modifiers" do
      template = ~AI"Hello"i
      assert template.text == "Hello"
    end

    test "raises error for nil input" do
      assert_raise ArgumentError, "prompt template string cannot be nil", fn ->
        sigil_AI(nil, [])
      end
    end
  end

  describe "template integration" do
    test "works with template formatting" do
      template = ~AI"Hello <%= @name %>, you are <%= @age %> years old"
      result = Jido.AI.Prompt.Template.format(template, %{name: "Alice", age: 30})
      assert result == "Hello Alice, you are 30 years old"
    end

    test "works with template composition" do
      intro = ~AI"You are talking to <%= @name %>"
      body = ~AI"They are <%= @age %> years old"

      full = ~AI"""
      <%= @intro %>
      <%= @body %>
      """

      result =
        Jido.AI.Prompt.Template.format_composed(
          full,
          %{intro: intro, body: body},
          %{name: "Bob", age: 25}
        )

      assert String.trim(result) == "You are talking to Bob\nThey are 25 years old"
    end
  end
end
