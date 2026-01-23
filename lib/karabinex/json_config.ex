defmodule Karabinex.JsonConfig do
  @type command_kind :: :app | :quit | :kill | :sh | :raycast
  @type repeat_value :: :key | :keymap
  @type option :: {:repeat, repeat_value()}
  @type command_def :: {command_kind(), String.t()} | {command_kind(), String.t(), [option()]}
  @type binding :: command_def() | bindings()
  @type bindings :: %{optional(String.t()) => binding()}

  @type json_map :: %{optional(String.t()) => term()}

  @command_keys %{
    "app" => :app,
    "quit" => :quit,
    "kill" => :kill,
    "sh" => :sh,
    "raycast" => :raycast
  }

  @reserved_key_names MapSet.new(Map.keys(@command_keys) ++ ["repeat"])
  @top_level_keys MapSet.new(["bindings", "version"])

  @spec parse_json!(String.t()) :: bindings()
  def parse_json!(json) do
    json
    |> Jason.decode!()
    |> parse_map!()
  end

  @spec parse_map!(json_map()) :: bindings()
  def parse_map!(%{} = data) do
    {bindings, version} = extract_bindings!(data)
    validate_version!(version)
    parse_keymap!(bindings, [])
  end

  def parse_map!(_data) do
    raise "JSON config must be an object"
  end

  @spec extract_bindings!(json_map()) :: {json_map(), integer() | nil}
  defp extract_bindings!(%{"bindings" => bindings} = root) when is_map(bindings) do
    validate_top_level_keys!(root)
    {bindings, Map.get(root, "version")}
  end

  defp extract_bindings!(%{"bindings" => _}) do
    raise "bindings must be an object"
  end

  defp extract_bindings!(%{} = root) do
    if Map.has_key?(root, "version") do
      raise "Missing bindings"
    else
      raise "Missing bindings"
    end
  end

  @spec validate_top_level_keys!(json_map()) :: :ok | no_return()
  defp validate_top_level_keys!(root) do
    unknown =
      root
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(@top_level_keys, &1))

    if unknown == [] do
      :ok
    else
      raise "Unknown top-level keys: #{Enum.join(unknown, ", ")}"
    end
  end

  @spec validate_version!(nil | pos_integer()) :: :ok
  defp validate_version!(nil), do: :ok

  defp validate_version!(version) when is_integer(version) and version > 0, do: :ok

  defp validate_version!(version), do: raise("Invalid version: #{inspect(version)}")

  @spec parse_keymap!(json_map(), [String.t()]) :: bindings()
  defp parse_keymap!(%{} = map, path) do
    if map_size(map) == 0 do
      raise "Empty keymap at #{path_label(path)}"
    end

    Enum.reduce(map, %{}, fn {key, value}, acc ->
      if not is_binary(key) do
        raise "Key must be a string at #{path_label(path)}"
      end

      if MapSet.member?(@reserved_key_names, key) do
        raise "Reserved key #{inspect(key)} at #{path_label(path)}"
      end

      Map.put(acc, key, parse_binding!(value, path ++ [key]))
    end)
  end

  @spec parse_binding!(term(), [String.t()]) :: binding()
  defp parse_binding!(%{} = value, path) do
    command_keys = Enum.filter(Map.keys(@command_keys), &Map.has_key?(value, &1))

    case command_keys do
      [] ->
        parse_keymap!(value, path)

      [command_key] ->
        parse_command!(value, command_key, path)

      _ ->
        raise "Multiple command keys at #{path_label(path)}"
    end
  end

  defp parse_binding!(_value, path) do
    raise "Binding must be an object at #{path_label(path)}"
  end

  @spec parse_command!(json_map(), String.t(), [String.t()]) :: command_def()
  defp parse_command!(value, command_key, path) do
    arg = Map.get(value, command_key)

    if not is_binary(arg) do
      raise "Command #{inspect(command_key)} argument must be a string at #{path_label(path)}"
    end

    repeat = parse_repeat!(Map.get(value, "repeat"), path)

    extras = Map.drop(value, [command_key, "repeat"])

    if map_size(extras) > 0 do
      raise "Unknown command keys #{inspect(Map.keys(extras))} at #{path_label(path)}"
    end

    kind = Map.fetch!(@command_keys, command_key)

    case repeat do
      nil -> {kind, arg}
      repeat_value -> {kind, arg, [repeat: repeat_value]}
    end
  end

  @spec parse_repeat!(String.t() | nil, [String.t()]) :: repeat_value() | nil
  defp parse_repeat!(nil, _path), do: nil

  defp parse_repeat!("key", _path), do: :key

  defp parse_repeat!("keymap", _path), do: :keymap

  defp parse_repeat!(value, path) do
    raise "Invalid repeat value #{inspect(value)} at #{path_label(path)}"
  end

  @spec path_label([String.t()]) :: String.t()
  defp path_label([]), do: "root"

  defp path_label(path), do: Enum.map_join(path, " -> ", &inspect/1)
end
