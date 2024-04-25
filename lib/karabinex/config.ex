defmodule Karabinex.Config do
  alias Karabinex.{Key, Keymap, Command, Chord}

  def parse_definitions(defs, prefix_chord \\ Chord.new()) do
    Enum.map(defs, &parse_definition(&1, prefix_chord))
  end

  def parse_definition({key, %{} = keymap_spec}, prefix_chord) do
    chord = Chord.append(prefix_chord, Key.new(key))
    Keymap.new(chord, parse_definitions(keymap_spec, chord))
  end

  def parse_definition({key, {kind, arg}}, prefix_chord) do
    parse_definition({key, {kind, arg, []}}, prefix_chord)
  end

  def parse_definition({key, {kind, arg, opts}}, prefix_chord) do
    chord = Chord.append(prefix_chord, Key.new(key))
    Command.new(kind, arg, chord, opts)
  end
end
