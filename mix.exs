defmodule JidoAi.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/agentjido/jido_ai"

  def project do
    [
      app: :jido_ai,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "Jido AI",
      description: "Jido Actions and Workflows for interacting with LLMs",
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.12"},
      {:jido, "~> 1.0.0-rc.3"},
      # Hex does not yet have a release of `instructor` that supports the `Instructor.Adapters.Anthropic` adapter.
      {:instructor, github: "thmsmlr/instructor_ex", branch: "main"},
      {:langchain, "~> 0.3.0-rc.1"},

      # Testing
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:mimic, "~> 1.10"}
    ]
  end

  defp aliases do
    [
      test: "test --trace"
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Mike Hostetler"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end
