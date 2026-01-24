defmodule Karabinex.Manipulator.CaptureModifierTest do
  use ExUnit.Case

  alias Karabinex.{ToManipulator, Chord, Key}
  alias Karabinex.Manipulator.CaptureModifier

  describe "new/2" do
    test "creates CaptureModifier with modifier and chord" do
      chord = Chord.new() |> Chord.append(Key.new("x"))

      result = CaptureModifier.new("left_option", chord)

      assert result.modifier == "left_option"
      assert result.chord == chord
    end
  end

  describe "ToManipulator.manipulator/1" do
    test "generates manipulator that matches modifier key" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      cm = CaptureModifier.new("left_option", chord)

      result = ToManipulator.manipulator(cm)

      assert result.type == :basic
      assert result.from == %{key_code: "left_option"}
    end

    test "remaps to same key" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      cm = CaptureModifier.new("left_shift", chord)

      result = ToManipulator.manipulator(cm)

      assert Enum.any?(result.to, fn
               %{key_code: "left_shift"} -> true
               _ -> false
             end)
    end

    test "adds if_variable condition for chord's variable" do
      chord = Chord.new() |> Chord.append(Key.new("r"))
      cm = CaptureModifier.new("left_control", chord)

      result = ToManipulator.manipulator(cm)

      assert Enum.any?(result.conditions, fn
               %{type: :variable_if, name: "karabinex_r_map", value: 1} -> true
               _ -> false
             end)
    end

    test "unsets variable after key up" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      cm = CaptureModifier.new("left_option", chord)

      result = ToManipulator.manipulator(cm)

      assert Enum.any?(result.to_after_key_up, fn
               %{set_variable: %{name: "karabinex_x_map", type: "unset"}} -> true
               _ -> false
             end)
    end

    test "does not unset variable after key up when disabled" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      cm = CaptureModifier.new("left_option", chord, false)

      result = ToManipulator.manipulator(cm)

      refute Map.has_key?(result, :to_after_key_up)
    end

    test "works with multi-key chord" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("r"))
        |> Chord.append(Key.new("a"))

      cm = CaptureModifier.new("right_command", chord)

      result = ToManipulator.manipulator(cm)

      assert Enum.any?(result.conditions, fn
               %{type: :variable_if, name: "karabinex_r_a_map", value: 1} -> true
               _ -> false
             end)
    end
  end
end
