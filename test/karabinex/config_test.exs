defmodule Karabinex.ConfigTest do
  use ExUnit.Case

  alias Karabinex.{Config, Chord, Command, Keymap}

  describe "preprocess/1" do
    test "leaves plain commands unchanged" do
      input = %{a: {:app, "Emacs"}}
      assert Config.preprocess(input) == %{a: {:app, "Emacs"}}
    end

    test "leaves repeat: :keymap unchanged" do
      input = %{a: {:app, "Emacs", repeat: :keymap}}
      assert Config.preprocess(input) == %{a: {:app, "Emacs", repeat: :keymap}}
    end

    test "expands repeat: :key into keymap with hook" do
      input = %{c: {:raycast, "confetti", repeat: :key}}

      expected = %{
        c: %{
          :__hook__ => {:raycast, "confetti"},
          c: {:raycast, "confetti", repeat: :keymap}
        }
      }

      assert Config.preprocess(input) == expected
    end

    test "handles nested maps" do
      input = %{
        r: %{
          c: {:raycast, "confetti", repeat: :key}
        }
      }

      expected = %{
        r: %{
          c: %{
            :__hook__ => {:raycast, "confetti"},
            c: {:raycast, "confetti", repeat: :keymap}
          }
        }
      }

      assert Config.preprocess(input) == expected
    end

    test "raises when repeat: :key combined with other options" do
      input = %{a: {:app, "Emacs", repeat: :key, if: %{foo: "bar"}}}

      assert_raise RuntimeError, ~r/repeat: :key cannot be combined/, fn ->
        Config.preprocess(input)
      end
    end
  end

  describe "parse_definition/2 with __hook__" do
    test "keymap without hook has nil hook" do
      input = {:r, %{a: {:app, "Emacs"}}}
      result = Config.parse_definition(input, Chord.new())

      assert %Keymap{hook: nil} = result
    end

    test "keymap with __hook__ has hook attached" do
      input = {:r, %{:__hook__ => {:raycast, "confetti"}, c: {:app, "Emacs"}}}
      result = Config.parse_definition(input, Chord.new())

      assert %Keymap{hook: %Command{kind: :raycast, arg: "confetti"}} = result
    end

    test "hook command has keymap's chord" do
      input = {:r, %{:__hook__ => {:raycast, "confetti"}, c: {:app, "Emacs"}}}
      result = Config.parse_definition(input, Chord.new())

      assert %Keymap{chord: chord, hook: %Command{chord: hook_chord}} = result
      assert chord == hook_chord
    end

    test "children are parsed correctly with hook present" do
      input = {:r, %{:__hook__ => {:raycast, "confetti"}, c: {:app, "Emacs"}}}
      result = Config.parse_definition(input, Chord.new())

      assert %Keymap{children: [%Command{kind: :app, arg: "Emacs"}]} = result
    end

    test "raises when hook has options" do
      input = {:r, %{:__hook__ => {:raycast, "confetti", some: :opt}, c: {:app, "Emacs"}}}

      assert_raise RuntimeError, ~r/Can't pass options to hooks/, fn ->
        Config.parse_definition(input, Chord.new())
      end
    end
  end
end
