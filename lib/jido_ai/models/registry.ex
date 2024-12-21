defmodule JidoAi.Models.Registry do
  @moduledoc """
  Provides a central registry for all model providers.
  """

  alias JidoAi.Models.Types

  @providers %{
    openai: JidoAi.Models.Providers.OpenAI,
    anthropic: JidoAi.Models.Providers.Anthropic
    # Add other providers here
  }

  @spec get_provider(atom()) :: module() | nil
  def get_provider(provider_name) do
    Map.get(@providers, provider_name)
  end

  @spec list_providers() :: [atom()]
  def list_providers do
    Map.keys(@providers)
  end

  @spec get_model(atom(), Types.model_class()) :: String.t() | nil
  def get_model(provider_name, model_class) do
    case get_provider(provider_name) do
      nil -> nil
      provider -> provider.get_model(model_class)
    end
  end
end
