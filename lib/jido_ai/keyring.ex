defmodule Jido.AI.Keyring do
  @moduledoc """
  GenServer that manages environment variables and application config.
  Serves as the source of truth for configuration values.

  Values can be loaded from:
  1. Environment variables (via Dotenvy, highest priority)
  2. Application environment (under :jido_ai, :keyring)
  3. Default values (lowest priority)

  Values can also be set on a per-session (per-process) basis.
  """

  use GenServer
  require Logger

  # Process registry for session keys
  @session_registry :jido_ai_keyring_sessions

  @default_name __MODULE__

  # Ensure ETS table exists
  defp ensure_session_registry(registry_name) do
    if :ets.whereis(registry_name) == :undefined do
      :ets.new(registry_name, [:set, :public, :named_table])
    end
  end

  def child_spec(opts) do
    name = Keyword.get(opts, :name, @default_name)

    %{
      id: name,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, @default_name)
    registry = Keyword.get(opts, :registry, @session_registry)

    # Ensure ETS table exists before starting GenServer
    ensure_session_registry(registry)

    GenServer.start_link(__MODULE__, registry, name: name)
  end

  @impl true
  def init(registry) do
    Logger.debug("Initializing environment variables")

    # Load environment variables
    env = load_from_env()

    # Load application environment
    app_env = load_from_app_env()

    # Merge with priority: env vars > app env
    keys = Map.merge(app_env, env)

    {:ok, %{keys: keys, registry: registry}}
  end

  # Load all environment variables and convert to atoms
  defp load_from_env do
    env_dir_prefix = Path.expand("./envs/")

    Dotenvy.source!([
      Path.join(File.cwd!(), ".env"),
      Path.absname(".env", env_dir_prefix),
      Path.absname(".#{Mix.env()}.env", env_dir_prefix),
      Path.absname(".#{Mix.env()}.overrides.env", env_dir_prefix),
      System.get_env()
    ])
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      atom_key = env_var_to_atom(key)
      Map.put(acc, atom_key, value)
    end)
  end

  # Convert environment variable name to atom
  defp env_var_to_atom(env_var) do
    env_var
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/, "_")
    |> String.to_atom()
  end

  # Load keys from application environment
  defp load_from_app_env do
    case Application.get_env(:jido_ai, :keyring) do
      nil ->
        %{}

      config when is_map(config) ->
        config

      _ ->
        %{}
    end
  end

  @doc """
  Lists all available keys in the keyring.
  Returns a list of atoms representing the available keys.
  """
  def list(server \\ @default_name) do
    GenServer.call(server, :list_keys)
  end

  @doc """
  Gets a value, checking session values first, then falling back to environment values.
  """
  def get(server \\ @default_name, key, default \\ nil) when is_atom(key) do
    case get_session_value(server, key) do
      nil -> get_env_value(server, key, default)
      value -> value
    end
  end

  @doc """
  Gets a value from the environment-level storage.
  """
  def get_env_value(server \\ @default_name, key, default \\ nil) when is_atom(key) do
    GenServer.call(server, {:get_value, key, default})
  end

  @doc """
  Sets a session-specific value that will override the environment value
  for the current process only.
  """
  def set_session_value(server \\ @default_name, key, value) when is_atom(key) do
    registry = GenServer.call(server, :get_registry)
    pid = self()
    :ets.insert(registry, {{pid, key}, value})
    :ok
  end

  @doc """
  Gets a session-specific value for the current process.
  Returns nil if no session value is set.
  """
  def get_session_value(server \\ @default_name, key) when is_atom(key) do
    registry = GenServer.call(server, :get_registry)
    pid = self()

    case :ets.lookup(registry, {pid, key}) do
      [{{^pid, ^key}, value}] -> value
      [] -> nil
    end
  end

  @doc """
  Clears a session-specific value for the current process.
  """
  def clear_session_value(server \\ @default_name, key) when is_atom(key) do
    registry = GenServer.call(server, :get_registry)
    pid = self()
    :ets.delete(registry, {pid, key})
    :ok
  end

  @doc """
  Clears all session-specific values for the current process.
  """
  def clear_all_session_values(server \\ @default_name) do
    registry = GenServer.call(server, :get_registry)
    pid = self()
    :ets.match_delete(registry, {{pid, :_}, :_})
    :ok
  end

  @impl true
  def handle_call({:get_value, key, default}, _from, %{keys: keys} = state) do
    {:reply, Map.get(keys, key, default), state}
  end

  @impl true
  def handle_call(:list_keys, _from, %{keys: keys} = state) do
    {:reply, Map.keys(keys), state}
  end

  @impl true
  def handle_call(:get_registry, _from, %{registry: registry} = state) do
    {:reply, registry, state}
  end

  # For testing - allows direct manipulation of the state
  @impl true
  def handle_call({:set_test_env_vars, env_vars}, _from, %{keys: keys} = state)
      when is_map(env_vars) do
    # Convert string keys to atoms
    atom_env_vars =
      Enum.reduce(env_vars, %{}, fn {key, value}, acc ->
        atom_key = env_var_to_atom(key)
        Map.put(acc, atom_key, value)
      end)

    # Merge with existing state, with new values taking precedence
    new_keys = Map.merge(keys, atom_env_vars)
    {:reply, :ok, %{state | keys: new_keys}}
  end

  @doc """
  Gets an environment variable with a default value.
  """
  def get_env_var(key, default \\ nil) do
    try do
      Dotenvy.env!(key, :string)
    rescue
      _ -> default
    end
  end

  @doc """
  Checks if a value exists and is non-empty.
  """
  def has_value?(nil), do: false
  def has_value?(""), do: false
  def has_value?(value) when is_binary(value), do: true
  def has_value?(_), do: false

  @doc """
  For backward compatibility - gets a key using the old method name
  """
  def get_key(server \\ @default_name, id) when is_atom(id) do
    get(server, id, "")
  end

  @doc """
  For backward compatibility - gets an env key using the old method name
  """
  def get_env_key(server \\ @default_name, id) when is_atom(id) do
    get_env_value(server, id, "")
  end

  @doc """
  For backward compatibility - sets a session key using the old method name
  """
  def set_session_key(server \\ @default_name, id, value) when is_atom(id) do
    set_session_value(server, id, value)
  end

  @doc """
  For backward compatibility - gets a session key using the old method name
  """
  def get_session_key(server \\ @default_name, id) when is_atom(id) do
    get_session_value(server, id)
  end

  @doc """
  For backward compatibility - clears a session key using the old method name
  """
  def clear_session_key(server \\ @default_name, id) when is_atom(id) do
    clear_session_value(server, id)
  end

  @doc """
  For backward compatibility - clears all session keys using the old method name
  """
  def clear_all_session_keys(server \\ @default_name) do
    clear_all_session_values(server)
  end
end
