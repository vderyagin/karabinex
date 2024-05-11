defmodule Karabinex.Config do
  alias Karabinex.{Key, Keymap, Command, Chord}

  def parse_definitions(defs, prefix \\ Chord.new()) do
    Enum.map(defs, &parse_definition(&1, prefix))
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
      :key ->
        new_opts = opts |> Keyword.merge(repeat: :keymap)

        {key, %{key => {kind, arg, new_opts}}}
        |> parse_definition(prefix)
        |> Keymap.add_hook(Command.new(chord, kind, arg, opts))

      :keymap ->
        Command.new(chord, kind, arg, opts |> Keyword.merge(repeat: true))

      _ ->
        Command.new(chord, kind, arg, opts)
    end
  end
end
