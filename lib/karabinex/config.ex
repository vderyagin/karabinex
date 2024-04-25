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
    prefix
    |> Chord.append(Key.new(key))
    |> Command.new(kind, arg, opts)
  end
end
