defmodule Karabinex.KeymapTest do
  use ExUnit.Case

  alias Karabinex.{Keymap, Command, Chord, Key}

  describe "new/2" do
    test "creates keymap with chord and empty children" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      keymap = Keymap.new(chord, [])

      assert keymap.chord == chord
      assert keymap.children == []
      assert keymap.hook == nil
    end

    test "creates keymap with children" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      child_chord = chord |> Chord.append(Key.new("a"))
      command = Command.new(child_chord, :app, "Emacs")

      keymap = Keymap.new(chord, [command])

      assert keymap.chord == chord
      assert length(keymap.children) == 1
      assert hd(keymap.children) == command
    end

    test "creates keymap with nested keymaps as children" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      nested_chord = chord |> Chord.append(Key.new("y"))
      nested_keymap = Keymap.new(nested_chord, [])

      keymap = Keymap.new(chord, [nested_keymap])

      assert length(keymap.children) == 1
      assert %Keymap{} = hd(keymap.children)
    end
  end

  describe "add_hook/2" do
    test "attaches hook command to keymap" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      keymap = Keymap.new(chord, [])
      hook = Command.new(chord, :raycast, "confetti")

      keymap_with_hook = Keymap.add_hook(keymap, hook)

      assert keymap_with_hook.hook == hook
    end

    test "preserves existing children when adding hook" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      child_chord = chord |> Chord.append(Key.new("a"))
      command = Command.new(child_chord, :app, "Emacs")
      keymap = Keymap.new(chord, [command])
      hook = Command.new(chord, :sh, "notify")

      keymap_with_hook = Keymap.add_hook(keymap, hook)

      assert keymap_with_hook.hook == hook
      assert keymap_with_hook.children == [command]
    end
  end
end
