defmodule Jido.AI.Model.Provider.Adapter do
  @moduledoc """
  Defines the behavior that any provider adapter must implement.

  This allows for extending the system with new providers without modifying
  the core Provider module.
  """

  @doc """
  Returns the base URL for the provider's API.

  ## Parameters
    - provider: The provider struct

  ## Returns
    - The base URL as a string
  """
  @callback base_url() :: String.t()

  @doc """
  Fetches models from the provider's API.

  ## Parameters
    - opts: Options for the fetch operation (like API key, etc.)

  ## Returns
    - {:ok, models} on success
    - {:error, reason} on failure
  """
  @callback list_models(opts :: keyword()) ::
              {:ok, list(map())} | {:error, any()}

  @doc """
  Fetches a specific model by ID from the provider's API.

  ## Parameters
    - model_id: The ID of the model to fetch
    - opts: Options for the fetch operation (like API key, etc.)

  ## Returns
    - {:ok, model} on success
    - {:error, reason} on failure
  """
  @callback model(model_id :: String.t(), opts :: keyword()) ::
              {:ok, map()} | {:error, any()}

  @doc """
  Normalizes a model ID to ensure it's in the correct format for the provider.

  ## Parameters
    - model_id: The ID of the model to normalize
    - opts: Options for the normalization

  ## Returns
    - {:ok, normalized_id} on success
    - {:error, reason} on failure
  """
  @callback normalize(model_id :: String.t(), opts :: keyword()) ::
              {:ok, String.t()} | {:error, any()}

  @doc """
  Returns the headers required for API requests to the provider.

  ## Parameters
    - provider: The provider struct
    - opts: Options for the request (like API key, etc.)

  ## Returns
    - A map of headers
  """
  @callback request_headers(opts :: keyword()) :: map()

  @doc """
  Returns the provider definition.

  ## Returns
    - A provider struct
  """
  @callback definition() :: Jido.AI.Provider.t()
end
