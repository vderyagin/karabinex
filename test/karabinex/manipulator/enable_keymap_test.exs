defmodule Karabinex.Manipulator.EnableKeymapTest do
  use ExUnit.Case

  alias Karabinex.{ToManipulator, Keymap, Command, Chord, Key}
  alias Karabinex.Manipulator.EnableKeymap

  describe "new/1" do
    test "wraps keymap in EnableKeymap struct" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      keymap = Keymap.new(chord, [])

      result = EnableKeymap.new(keymap)

      assert %EnableKeymap{keymap: ^keymap, other_chords: []} = result
    end
  end

  describe "register_other_chords/2" do
    test "registers other chords for singleton keymap" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      keymap = Keymap.new(chord, [])
      ek = EnableKeymap.new(keymap)

      other_chord = Chord.new() |> Chord.append(Key.new("y"))
      result = EnableKeymap.register_other_chords(ek, [other_chord])

      assert result.other_chords == [other_chord]
    end

    test "filters out prefix chord for non-singleton keymap" do
      parent_chord = Chord.new() |> Chord.append(Key.new("r"))
      chord = parent_chord |> Chord.append(Key.new("a"))
      keymap = Keymap.new(chord, [])
      ek = EnableKeymap.new(keymap)

      result = EnableKeymap.register_other_chords(ek, [parent_chord])

      assert result.other_chords == []
    end
  end

  describe "ToManipulator.manipulator/1 for singleton chord" do
    test "generates manipulator without prefix variable check" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      keymap = Keymap.new(chord, [])
      ek = EnableKeymap.new(keymap)

      result = ToManipulator.manipulator(ek)

      assert result.type == :basic
      assert result.from == %{key_code: "x"}

      set_var =
        Enum.find(result.to, fn
          %{set_variable: %{name: _, value: 1}} -> true
          _ -> false
        end)

      assert set_var != nil
    end

    test "adds unless_variables for other chords" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      keymap = Keymap.new(chord, [])
      ek = EnableKeymap.new(keymap)

      other_chord = Chord.new() |> Chord.append(Key.new("y"))
      ek = EnableKeymap.register_other_chords(ek, [other_chord])

      result = ToManipulator.manipulator(ek)

      assert Enum.any?(result.conditions, fn
               %{type: :variable_if, value: 0} -> true
               _ -> false
             end)
    end
  end

  describe "ToManipulator.manipulator/1 for non-singleton chord without hook" do
    test "generates manipulator with prefix variable check" do
      parent_chord = Chord.new() |> Chord.append(Key.new("r"))
      chord = parent_chord |> Chord.append(Key.new("a"))
      keymap = Keymap.new(chord, [])
      ek = EnableKeymap.new(keymap)

      result = ToManipulator.manipulator(ek)

      assert result.type == :basic
      assert result.from == %{key_code: "a"}

      assert Enum.any?(result.conditions, fn
               %{type: :variable_if, name: "karabinex_r_map", value: 1} -> true
               _ -> false
             end)
    end

    test "unsets prefix variable and sets own variable" do
      parent_chord = Chord.new() |> Chord.append(Key.new("r"))
      chord = parent_chord |> Chord.append(Key.new("a"))
      keymap = Keymap.new(chord, [])
      ek = EnableKeymap.new(keymap)

      result = ToManipulator.manipulator(ek)

      has_unset =
        Enum.any?(result.to, fn
          %{set_variable: %{name: "karabinex_r_map", type: "unset"}} -> true
          _ -> false
        end)

      has_set =
        Enum.any?(result.to, fn
          %{set_variable: %{name: "karabinex_r_a_map", value: 1}} -> true
          _ -> false
        end)

      assert has_unset
      assert has_set
    end
  end

  describe "ToManipulator.manipulator/1 for non-singleton chord with hook" do
    test "includes hook shell command" do
      parent_chord = Chord.new() |> Chord.append(Key.new("r"))
      chord = parent_chord |> Chord.append(Key.new("c"))
      hook = Command.new(chord, :raycast, "confetti")
      keymap = Keymap.new(chord, []) |> Keymap.add_hook(hook)
      ek = EnableKeymap.new(keymap)

      result = ToManipulator.manipulator(ek)

      has_shell_cmd =
        Enum.any?(result.to, fn
          %{shell_command: cmd} -> cmd =~ "raycast"
          _ -> false
        end)

      assert has_shell_cmd
    end
  end
end
