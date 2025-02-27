defmodule Jido.AI.Message.ContentPart do
  @moduledoc """
  Represents a part of a message's content, which can be text or other media.
  """

  use TypedStruct

  typedstruct do
    field(:type, :text | :image_url, default: :text)
    field(:text, String.t())
    field(:image_url, String.t())
  end
end
