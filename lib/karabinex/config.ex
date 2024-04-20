defmodule Karabinex.Config do
  alias Karabinex.{Keymap, Command}

  def parse_definitions(defs, prefix \\ []) do
    defs
    |> Enum.map(&parse_definition(&1, prefix))
  end

  def parse_definition({key, %{} = keymap_spec}, prefix) do
    Keymap.new(key, prefix, parse_definitions(keymap_spec, prefix ++ [key]))
  end

  def parse_definition({key, {kind, arg}}, prefix) do
    parse_definition({key, {kind, arg, []}}, prefix)
  end

  def parse_definition({key, {kind, arg, opts}}, prefix) do
    Command.new(kind, arg, key, prefix, opts)
  end
end
