defmodule Jido.AI.Prompt.Sigil do
  @moduledoc """
  Defines the `~AI` sigil for creating prompt templates.

  ## Examples

      import Jido.AI.Prompt.Sigil

      template = ~AI"Hello, <%= @name %>! Welcome to <%= @service %>."
      Jido.AI.Prompt.Template.format(template, %{name: "Alice", service: "Jido AI"})
      #=> "Hello, Alice! Welcome to Jido AI."
  """

  @doc """
  Creates a prompt template from a string using the `~AI` sigil.
  """
  def sigil_AI(nil, _modifiers) do
    raise ArgumentError, "prompt template string cannot be nil"
  end

  def sigil_AI(string, _modifiers) do
    Jido.AI.Prompt.Template.from_string!(string)
  end
end
