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

  @spec generate(Keymap.t() | Command.t()) :: [struct()] | struct()
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

  @spec get_child_modifiers(Keymap.t()) :: [String.t()]
  def get_child_modifiers(%Keymap{children: children}) do
    children
    |> Enum.flat_map(fn %{chord: chord} ->
      Chord.last(chord).modifiers
    end)
    |> Enum.uniq()
    |> Enum.flat_map(&["left_#{&1}", "right_#{&1}"])
  end

  @spec make_from(Key.t()) :: %{
          optional(:key_code) => String.t(),
          optional(:consumer_key_code) => String.t(),
          optional(:pointing_button) => String.t(),
          optional(:modifiers) => %{mandatory: [Key.modifier()]}
        }
  def make_from(%Key{modifiers: modifiers} = key) do
    if Key.has_modifiers?(key) do
      Key.code(key)
      |> Map.merge(%{
        modifiers: %{
          mandatory: MapSet.to_list(modifiers)
        }
      })
    else
      Key.code(key)
    end
  end
end
