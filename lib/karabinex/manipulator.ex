defprotocol Karabinex.ToManipulator do
  def manipulator(data)
end

defmodule Karabinex.Manipulator do
  alias Karabinex.{
    Key,
    Keymap,
    Command,
    Chord
  }

  alias __MODULE__.{
    EnableKeymap,
    DisableKeymap,
    CaptureModifier,
    InvokeCommand
  }

  require Key

  def generate(%Keymap{children: children, chord: chord} = keymap) do
    [
      EnableKeymap.new(keymap),
      children |> Enum.map(&generate/1),
      keymap |> get_child_modifiers() |> Enum.map(&CaptureModifier.new(&1, chord)),
      DisableKeymap.new(keymap)
    ]
    |> List.flatten()
  end

  def generate(%Command{} = c), do: InvokeCommand.new(c)

  def get_child_modifiers(%Keymap{children: children}) do
    children
    |> Enum.flat_map(fn %{chord: chord} ->
      Chord.last(chord).modifiers
    end)
    |> Enum.uniq()
    |> Enum.flat_map(&["left_#{&1}", "right_#{&1}"])
  end

  def make_from(%Key{modifiers: modifiers} = key) when Key.has_modifiers?(key) do
    Key.code(key)
    |> Map.merge(%{
      modifiers: %{
        mandatory: MapSet.to_list(modifiers)
      }
    })
  end

  def make_from(%Key{} = key), do: Key.code(key)
end
