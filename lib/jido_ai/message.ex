defmodule Jido.AI.Message do
  @moduledoc """
  Represents a message in the system, which can be either from the user or the AI.
  """

  use TypedStruct

  typedstruct do
    field(:role, :user | :assistant | :system, default: :user)
    field(:content, String.t() | list(), enforce: true)
    field(:name, String.t(), default: nil)
  end

  @doc """
  Creates a new message struct.
  """
  def new(attrs) when is_map(attrs) do
    struct(__MODULE__, attrs)
  end

  @doc """
  Creates a new message struct. Raises if invalid.
  """
  def new!(attrs) when is_map(attrs) do
    case Map.fetch(attrs, :content) do
      {:ok, _content} -> new(attrs)
      :error -> raise ArgumentError, "content is required"
    end
  end

  @doc """
  Creates a new user message with the given content.
  """
  def new_user(content) when is_binary(content) do
    new(%{role: :user, content: content})
  end

  @doc """
  Creates a new user message with the given content. Raises if invalid.
  """
  def new_user!(content) when is_binary(content) do
    new!(%{role: :user, content: content})
  end

  @doc """
  Creates a new assistant message with the given content.
  """
  def new_assistant(content) when is_binary(content) do
    new(%{role: :assistant, content: content})
  end

  @doc """
  Creates a new assistant message with the given content. Raises if invalid.
  """
  def new_assistant!(content) when is_binary(content) do
    new!(%{role: :assistant, content: content})
  end

  @doc """
  Creates a new system message with the given content.
  """
  def new_system(content) when is_binary(content) do
    new(%{role: :system, content: content})
  end

  @doc """
  Creates a new system message with the given content. Raises if invalid.
  """
  def new_system!(content) when is_binary(content) do
    new!(%{role: :system, content: content})
  end
end
