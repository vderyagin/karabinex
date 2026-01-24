defmodule Karabinex.ManipulatorTest do
  use ExUnit.Case

  alias Karabinex.{Chord, Command, Key, Keymap, Manipulator}
  alias Karabinex.Manipulator.CaptureModifier

  test "keeps keymap active on modifier release for repeatable commands" do
    chord = Chord.new() |> Chord.append(Key.new("x"))
    cmd_chord = chord |> Chord.append(Key.new("C-b"))
    command = Command.new(cmd_chord, :raycast, "confetti", repeat: true)
    keymap = Keymap.new(chord, [command])

    result = Manipulator.generate(keymap)

    assert Enum.any?(result, fn
             %CaptureModifier{modifier: "left_control", unset_on_key_up: false} -> true
             _ -> false
           end)

    assert Enum.any?(result, fn
             %CaptureModifier{modifier: "right_control", unset_on_key_up: false} -> true
             _ -> false
           end)
  end

  test "still unsets keymap on modifier release for non-repeatable commands" do
    chord = Chord.new() |> Chord.append(Key.new("x"))
    cmd_chord = chord |> Chord.append(Key.new("C-b"))
    command = Command.new(cmd_chord, :raycast, "confetti", repeat: false)
    keymap = Keymap.new(chord, [command])

    result = Manipulator.generate(keymap)

    assert Enum.any?(result, fn
             %CaptureModifier{modifier: "left_control", unset_on_key_up: true} -> true
             _ -> false
           end)

    assert Enum.any?(result, fn
             %CaptureModifier{modifier: "right_control", unset_on_key_up: true} -> true
             _ -> false
           end)
  end
end
