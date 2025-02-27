defmodule Mix.Tasks.Jido.Ai.ListProviders do
  @moduledoc """
  Lists all available AI providers in the system.

  ## Examples

      mix jido.ai.list_providers

  """
  use Mix.Task
  require Logger
  alias Jido.AI.Provider

  @shortdoc "Lists all available AI providers"

  @impl Mix.Task
  def run(_args) do
    # Start the required applications
    Application.ensure_all_started(:jido_ai)

    list_providers()
  end

  defp list_providers do
    IO.puts("\nAvailable AI Providers:\n")

    Provider.list()
    |> Enum.sort_by(& &1.id)
    |> Enum.each(fn provider ->
      IO.puts("#{provider.id}: #{provider.name}")
      IO.puts("  Description: #{provider.description}")
      IO.puts("  Type: #{provider.type}")
      IO.puts("  API Base URL: #{provider.api_base_url}")
      IO.puts("  Requires API Key: #{provider.requires_api_key}")
      IO.puts("")
    end)

    IO.puts("Total providers: #{length(Provider.list())}")
  end
end
