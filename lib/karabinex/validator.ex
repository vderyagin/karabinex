defmodule Karabinex.Validator do
  alias Karabinex.Key

  @valid_kinds [:app, :quit, :kill, :sh, :remap, :raycast]
  @valid_opts [:repeat]

  def validate!(defs) do
    validate_definitions!(defs, _depth = 0)
    defs
  end

  defp validate_definitions!(defs, depth) do
    validate_not_empty!(defs, depth)
    validate_hook!(defs, depth)
    validate_no_duplicates!(defs)
    Enum.each(defs, &validate_definition!(&1, depth))
  end

  defp validate_hook!(%{__hook__: _}, 0) do
    raise "__hook__ cannot be used at top level"
  end

  defp validate_hook!(%{__hook__: {_kind, _arg, opts}}, _depth) do
    raise "Hook cannot have options: #{inspect(opts)}"
  end

  defp validate_hook!(%{__hook__: {kind, arg}}, _depth) do
    validate_kind!(kind)
    validate_arg!(arg)
  end

  defp validate_hook!(%{}, _depth), do: :ok

  defp validate_not_empty!(%{} = defs, 0) when map_size(defs) == 0 do
    raise "Config cannot be empty"
  end

  defp validate_not_empty!(%{} = defs, _depth) when map_size(defs) == 0 do
    raise "Empty keymap is not allowed"
  end

  defp validate_not_empty!(_defs, _depth), do: :ok

  @spec validate_no_duplicates!(map()) :: :ok | no_return()
  defp validate_no_duplicates!(defs) do
    defs
    |> find_duplicate_keys()
    |> then(fn
      [] ->
        :ok

      dups ->
        keys =
          dups
          |> Enum.map(fn keys -> Enum.map_join(keys, ", ", &inspect/1) end)
          |> Enum.join("; ")

        raise("Duplicate keys detected: #{keys}")
    end)
  end

  defp find_duplicate_keys(defs) do
    defs
    |> Enum.reject(fn {key, _} -> key == :__hook__ end)
    |> Enum.map(fn {key, _} -> {key, Key.new(key)} end)
    |> Enum.group_by(fn {_raw, parsed} -> {parsed.code, parsed.modifiers} end)
    |> Enum.filter(fn {_normalized, entries} -> length(entries) > 1 end)
    |> Enum.map(fn {_normalized, entries} -> Enum.map(entries, &elem(&1, 0)) end)
  end

  defp validate_definition!({:__hook__, _value}, _depth) do
    :ok
  end

  defp validate_definition!({key, %{} = nested}, depth) do
    validate_key!(key)
    validate_definitions!(nested, depth + 1)
  end

  defp validate_definition!({key, {kind, arg}}, depth) do
    validate_key!(key)
    validate_kind!(kind)
    validate_arg!(arg)
    validate_no_repeat_at_top!([], depth, key)
  end

  defp validate_definition!({key, {kind, arg, opts}}, depth) do
    validate_key!(key)
    validate_kind!(kind)
    validate_arg!(arg)
    validate_opts!(opts)
    validate_no_repeat_at_top!(opts, depth, key)
  end

  defp validate_key!(key) do
    _ = Key.new(key)
    :ok
  rescue
    e -> reraise "Invalid key #{inspect(key)}: #{Exception.message(e)}", __STACKTRACE__
  end

  defp validate_kind!(kind) when kind in @valid_kinds, do: :ok

  defp validate_kind!(kind) do
    raise "Unknown command type: #{inspect(kind)}. Valid types: #{inspect(@valid_kinds)}"
  end

  defp validate_arg!(arg) when is_binary(arg), do: :ok

  defp validate_arg!(arg) do
    raise "Command argument must be a string, got: #{inspect(arg)}"
  end

  defp validate_opts!(opts) do
    Enum.each(opts, fn {key, _value} ->
      if key not in @valid_opts do
        raise "Unknown option: #{inspect(key)}. Valid options: #{inspect(@valid_opts)}"
      end
    end)
  end

  defp validate_no_repeat_at_top!(opts, 0, key) do
    case opts[:repeat] do
      nil ->
        :ok

      value ->
        raise "repeat: #{inspect(value)} cannot be used at top level (key: #{inspect(key)})"
    end
  end

  defp validate_no_repeat_at_top!(_opts, _depth, _key), do: :ok
end
