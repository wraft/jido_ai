defmodule Mix.Tasks.Jido.Ai.CacheModels do
  @moduledoc """
  Fetches and caches models from a specified AI provider.

  This task allows you to fetch models from any provider and cache them locally.
  It can be used to refresh the local cache or to initialize it for the first time.

  ## Examples

      # Fetch models from a specific provider
      mix jido.ai.cache_models anthropic
      mix jido.ai.cache_models openai
      mix jido.ai.cache_models openrouter

      # Fetch models from all providers
      mix jido.ai.cache_models --all

      # Fetch a specific model and force refresh
      mix jido.ai.cache_models anthropic --model=claude-3-7-sonnet-20250219 --refresh

      # List available providers
      mix jido.ai.cache_models --list-providers

      # Verbose output with model details
      mix jido.ai.cache_models anthropic --verbose
  """
  use Mix.Task
  require Logger
  alias Jido.AI.Provider

  @shortdoc "Fetches and caches models from an AI provider"

  @impl Mix.Task
  def run(args) do
    # Start the required applications
    Application.ensure_all_started(:jido_ai)

    {opts, args, _} =
      OptionParser.parse(args,
        switches: [
          verbose: :boolean,
          all: :boolean,
          refresh: :boolean,
          model: :string,
          list_providers: :boolean
        ]
      )

    verbose = Keyword.get(opts, :verbose, false)
    refresh = Keyword.get(opts, :refresh, false)
    specific_model = Keyword.get(opts, :model)

    cond do
      Keyword.get(opts, :list_providers, false) ->
        list_available_providers()

      Keyword.get(opts, :all, false) ->
        fetch_all_providers(verbose: verbose, refresh: refresh)

      specific_model && length(args) > 0 ->
        provider_id = List.first(args)
        fetch_specific_model(provider_id, specific_model, verbose: verbose, refresh: refresh)

      length(args) > 0 ->
        provider_id = List.first(args)
        fetch_provider_models(provider_id, verbose: verbose, refresh: refresh)

      true ->
        show_usage()
    end
  end

  defp fetch_all_providers(opts) do
    IO.puts("\nFetching models from all providers...\n")

    Provider.list()
    |> Enum.each(fn provider ->
      fetch_provider_models(provider.id, opts)
      IO.puts("\n")
    end)

    IO.puts("\nAll provider models fetched and cached.\n")
  end

  defp fetch_provider_models(provider_id, opts) do
    verbose = Keyword.get(opts, :verbose, false)
    refresh = Keyword.get(opts, :refresh, false)

    case Provider.get_adapter_by_id(Provider.ensure_atom(provider_id)) do
      {:ok, adapter} ->
        provider = adapter.definition()
        IO.puts("\n--- Fetching models from: #{provider.name} (#{provider.id}) ---")

        # Set refresh option if specified
        list_opts = if refresh, do: [refresh: true], else: []

        case adapter.list_models(list_opts) do
          {:ok, models} ->
            IO.puts("Successfully fetched and cached #{length(models)} models.")

            if verbose do
              IO.puts("\nModel details:")

              Enum.take(models, 5)
              |> Enum.each(fn model ->
                print_model_details(model)
              end)
            else
              # Just print the first few model IDs
              sample = Enum.take(models, 3)
              IO.puts("Sample models: #{Enum.map_join(sample, ", ", & &1.id)}")
            end

            # Verify cache file exists
            models_file =
              Path.join([
                Provider.base_dir(),
                to_string(provider.id),
                "models.json"
              ])

            if File.exists?(models_file) do
              IO.puts("Models cached to: #{models_file}")
            else
              IO.puts("Warning: Models file not found at expected location: #{models_file}")
            end

          {:error, reason} ->
            IO.puts("Error fetching models: #{inspect(reason)}")
        end

      {:error, reason} ->
        IO.puts("Error: #{reason}")
        list_available_providers()
    end
  end

  defp fetch_specific_model(provider_id, model_id, opts) do
    verbose = Keyword.get(opts, :verbose, false)
    refresh = Keyword.get(opts, :refresh, false)

    case Provider.get_adapter_by_id(Provider.ensure_atom(provider_id)) do
      {:ok, adapter} ->
        provider = adapter.definition()
        IO.puts("\n--- Fetching model from: #{provider.name} (#{provider.id}) ---")
        IO.puts("Model ID: #{model_id}")

        # Always set save_to_cache to true and use refresh if specified
        model_opts = [save_to_cache: true, refresh: refresh]

        case adapter.model(model_id, model_opts) do
          {:ok, model} ->
            IO.puts("Successfully fetched and cached model: #{model.id}")

            if verbose do
              print_model_details(model)
            end

            # Verify cache file exists
            model_file =
              Path.join([
                Provider.base_dir(),
                to_string(provider.id),
                "models",
                "#{model_id}.json"
              ])

            if File.exists?(model_file) do
              IO.puts("Model cached to: #{model_file}")
            else
              IO.puts("Warning: Model file not found at expected location: #{model_file}")
            end

          {:error, reason} ->
            IO.puts("Error fetching model: #{inspect(reason)}")
        end

      {:error, reason} ->
        IO.puts("Error: #{reason}")
        list_available_providers()
    end
  end

  defp print_model_details(model) do
    IO.puts("\n  ID: #{model.id}")
    IO.puts("  Name: #{model.name}")
    IO.puts("  Description: #{model.description || "N/A"}")

    # Print capabilities if available
    if Map.has_key?(model, :capabilities) do
      caps = model.capabilities
      IO.puts("  Capabilities:")
      IO.puts("    Chat: #{caps.chat}")
      IO.puts("    Embedding: #{caps.embedding}")
      IO.puts("    Image: #{caps.image}")
      IO.puts("    Vision: #{caps.vision}")
      IO.puts("    Multimodal: #{caps.multimodal}")
      IO.puts("    Audio: #{caps.audio}")
      IO.puts("    Code: #{caps.code}")
    end

    # Print tier if available
    if Map.has_key?(model, :tier) do
      tier = model.tier
      IO.puts("  Tier: #{tier.value} - #{tier.description}")
    end
  end

  defp list_available_providers do
    IO.puts("\nAvailable providers:")

    Provider.list()
    |> Enum.sort_by(& &1.id)
    |> Enum.each(fn provider ->
      IO.puts("  #{provider.id}: #{provider.name} - #{provider.description}")
    end)
  end

  defp show_usage do
    IO.puts("""
    Usage:
      mix jido.ai.cache_models PROVIDER_ID [--verbose] [--refresh]
      mix jido.ai.cache_models PROVIDER_ID --model=MODEL_ID [--verbose] [--refresh]
      mix jido.ai.cache_models --all [--verbose] [--refresh]
      mix jido.ai.cache_models --list-providers

    Examples:
      mix jido.ai.cache_models anthropic
      mix jido.ai.cache_models openai --verbose
      mix jido.ai.cache_models anthropic --model=claude-3-7-sonnet-20250219 --refresh
      mix jido.ai.cache_models --all
    """)
  end
end
