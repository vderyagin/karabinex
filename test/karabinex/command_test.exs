defmodule Karabinex.CommandTest do
  use ExUnit.Case

  alias Karabinex.{Command, Chord, Key}

  describe "new/4" do
    test "creates command with chord, kind, and arg" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      command = Command.new(chord, :app, "Emacs")

      assert command.chord == chord
      assert command.kind == :app
      assert command.arg == "Emacs"
      assert command.repeat == false
    end

    test "creates command with all command kinds" do
      chord = Chord.new() |> Chord.append(Key.new("a"))

      assert %Command{kind: :app} = Command.new(chord, :app, "Finder")
      assert %Command{kind: :quit} = Command.new(chord, :quit, "Safari")
      assert %Command{kind: :kill} = Command.new(chord, :kill, "Firefox")
      assert %Command{kind: :sh} = Command.new(chord, :sh, "echo hello")
      assert %Command{kind: :raycast} = Command.new(chord, :raycast, "confetti")
    end
  end

  describe "add_opts/2" do
    test "adds repeat option" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      command = Command.new(chord, :app, "Emacs", repeat: true)

      assert command.repeat == true
    end

    test "defaults repeat to false" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      command = Command.new(chord, :app, "Emacs")

      assert command.repeat == false
    end

    test "handles empty options" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      command = Command.new(chord, :sh, "ls", [])

      assert command.repeat == false
    end
  end
end
