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

  def generate(%Keymap{chord: chord, children: children} = keymap) do
    [
      chord |> EnableKeymap.new(),
      children |> Enum.map(&generate/1),
      keymap |> get_child_modifiers() |> Enum.map(&CaptureModifier.new(&1, chord)),
      chord |> DisableKeymap.new()
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

  def make_from(%Key{modifiers: []} = key), do: Key.code(key)

  def make_from(%Key{modifiers: modifiers} = key) do
    Key.code(key)
    |> Map.merge(%{
      modifiers: %{
        mandatory: modifiers
      }
    })
  end
end
