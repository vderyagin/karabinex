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

  @type modifier_capture :: {String.t(), boolean()}

  @spec generate(Keymap.t() | Command.t()) :: [struct()] | struct()
  def generate(%Keymap{children: children, chord: chord} = keymap) do
    [
      EnableKeymap.new(keymap),
      children |> Enum.map(&generate/1),
      keymap
      |> get_child_modifiers()
      |> Enum.map(fn {modifier, unset_on_key_up} ->
        CaptureModifier.new(modifier, chord, unset_on_key_up)
      end),
      DisableKeymap.new(keymap)
    ]
    |> List.flatten()
  end

  def generate(%Command{} = c), do: InvokeCommand.new(c)

  @spec get_child_modifiers(Keymap.t()) :: [modifier_capture()]
  def get_child_modifiers(%Keymap{children: children}) do
    repeatable_modifiers =
      children
      |> Enum.flat_map(&repeatable_child_modifiers/1)
      |> MapSet.new()

    children
    |> Enum.flat_map(&child_modifiers/1)
    |> Enum.uniq()
    |> Enum.flat_map(fn modifier ->
      unset_on_key_up = not MapSet.member?(repeatable_modifiers, modifier)

      ["left_#{modifier}", "right_#{modifier}"]
      |> Enum.map(&{&1, unset_on_key_up})
    end)
  end

  @spec child_modifiers(Keymap.t() | Command.t()) :: [Key.modifier()]
  defp child_modifiers(%{chord: chord}) do
    chord
    |> Chord.last()
    |> Map.get(:modifiers)
    |> MapSet.to_list()
  end

  @spec repeatable_child_modifiers(Keymap.t() | Command.t()) :: [Key.modifier()]
  defp repeatable_child_modifiers(%Command{repeat: true} = command), do: child_modifiers(command)
  defp repeatable_child_modifiers(_child), do: []

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
