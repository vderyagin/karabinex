defmodule Karabinex.Manipulator.DisableKeymapTest do
  use ExUnit.Case

  alias Karabinex.{ToManipulator, Keymap, Chord, Key}
  alias Karabinex.Manipulator.DisableKeymap

  describe "new/1" do
    test "wraps keymap in DisableKeymap struct" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      keymap = Keymap.new(chord, [])

      result = DisableKeymap.new(keymap)

      assert %DisableKeymap{keymap: ^keymap} = result
    end
  end

  describe "ToManipulator.manipulator/1" do
    test "generates manipulator that matches any key" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      keymap = Keymap.new(chord, [])
      dk = DisableKeymap.new(keymap)

      result = ToManipulator.manipulator(dk)

      assert result.type == :basic
      assert result.from == %{any: :key_code}
    end

    test "adds if_variable condition for keymap's variable" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      keymap = Keymap.new(chord, [])
      dk = DisableKeymap.new(keymap)

      result = ToManipulator.manipulator(dk)

      assert result.conditions
             |> Enum.any?(&match?(%{type: :variable_if, name: "karabinex_x_map", value: 1}, &1))
    end

    test "unsets keymap's variable" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      keymap = Keymap.new(chord, [])
      dk = DisableKeymap.new(keymap)

      result = ToManipulator.manipulator(dk)

      assert result.to
             |> Enum.any?(&match?(%{set_variable: %{name: "karabinex_x_map", type: "unset"}}, &1))
    end

    test "works with multi-key chord" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("r"))
        |> Chord.append(Key.new("a"))

      keymap = Keymap.new(chord, [])
      dk = DisableKeymap.new(keymap)

      result = ToManipulator.manipulator(dk)

      assert result.conditions
             |> Enum.any?(&match?(%{type: :variable_if, name: "karabinex_r_a_map", value: 1}, &1))
    end
  end
end
