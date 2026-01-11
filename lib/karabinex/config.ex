defmodule Karabinex.Config do
  alias Karabinex.{Key, Keymap, Command, Chord}

  def preprocess(defs) do
    defs
    |> Enum.map(&expand_compound_key/1)
    |> validate_no_conflicting_expansions!()
    |> Enum.map(&preprocess_definition/1)
    |> Map.new()
  end

  defp validate_no_conflicting_expansions!(expanded) do
    expanded
    |> Enum.map(&to_string(elem(&1, 0)))
    |> Enum.frequencies()
    |> Enum.filter(fn {_k, v} -> v > 1 end)
    |> Enum.map(fn {k, _} -> k end)
    |> then(fn
      [] -> expanded
      dups -> raise "Compound key expansion creates duplicate keys: #{Enum.join(dups, ", ")}"
    end)
  end

  defp expand_compound_key({key, value}) do
    key_str = to_string(key)

    case String.split(key_str, " ", parts: 2) do
      [first, rest] ->
        expand_compound_key({first, %{rest => value}})

      [_single] ->
        {key, value}
    end
  end

  defp preprocess_definition({key, %{} = nested}) do
    {key, preprocess(nested)}
  end

  defp preprocess_definition({key, {kind, arg, opts}}) do
    case opts[:repeat] do
      :key ->
        other_opts = Keyword.delete(opts, :repeat)

        if other_opts != [] do
          raise "repeat: :key cannot be combined with other options: #{inspect(other_opts)}"
        end

        hook = {kind, arg}
        child = {kind, arg, repeat: :keymap}
        {key, %{:__hook__ => hook, key => child}}

      :keymap ->
        {key, {kind, arg, opts}}
    end
  end

  defp preprocess_definition({key, {kind, arg}}) do
    {key, {kind, arg}}
  end

  def parse_definitions(defs, prefix \\ Chord.new()) do
    Enum.map(defs, &parse_definition(&1, prefix))
  end

  def parse_definition({key, %{__hook__: {kind, arg}} = keymap_spec}, prefix) do
    chord = Chord.append(prefix, Key.new(key))
    children_spec = Map.delete(keymap_spec, :__hook__)
    keymap = Keymap.new(chord, parse_definitions(children_spec, chord))
    Keymap.add_hook(keymap, Command.new(chord, kind, arg))
  end

  def parse_definition({_key, %{__hook__: {_kind, _arg, _opts}}}, _prefix) do
    raise "Can't pass options to hooks"
  end

  def parse_definition({key, %{} = keymap_spec}, prefix) do
    chord = Chord.append(prefix, Key.new(key))
    Keymap.new(chord, parse_definitions(keymap_spec, chord))
  end

  def parse_definition({key, {kind, arg}}, prefix) do
    parse_definition({key, {kind, arg, []}}, prefix)
  end

  def parse_definition({key, {kind, arg, opts}}, prefix) do
    chord = prefix |> Chord.append(Key.new(key))

    case opts[:repeat] do
      :keymap ->
        Command.new(chord, kind, arg, opts |> Keyword.merge(repeat: true))

      _ ->
        Command.new(chord, kind, arg, opts)
    end
  end
end
