defmodule Karabinex.Manipulator.InvokeCommandTest do
  use ExUnit.Case

  alias Karabinex.{ToManipulator, Command, Chord, Key}
  alias Karabinex.Manipulator.InvokeCommand

  describe "command/2" do
    test "generates open command for :app" do
      result = InvokeCommand.command(:app, "Emacs")

      assert result == "open -a 'Emacs'"
    end

    test "generates raycast URL for :raycast" do
      result = InvokeCommand.command(:raycast, "confetti")

      assert result == "open raycast://confetti"
    end

    test "generates osascript quit for :quit" do
      result = InvokeCommand.command(:quit, "Safari")

      assert result == "osascript -e 'quit app \"Safari\"'"
    end

    test "generates killall for :kill" do
      result = InvokeCommand.command(:kill, "Firefox")

      assert result == "killall -SIGKILL 'Firefox'"
    end

    test "passes through shell command for :sh" do
      result = InvokeCommand.command(:sh, "echo hello")

      assert result == "echo hello"
    end
  end

  describe "new/1" do
    test "wraps command in InvokeCommand struct" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      command = Command.new(chord, :app, "Emacs")

      result = InvokeCommand.new(command)

      assert %InvokeCommand{command: ^command} = result
    end
  end

  describe "ToManipulator.manipulator/1" do
    test "generates manipulator for singleton chord command" do
      chord = Chord.new() |> Chord.append(Key.new("x"))
      command = Command.new(chord, :app, "Emacs")
      ic = InvokeCommand.new(command)

      result = ToManipulator.manipulator(ic)

      assert result.type == :basic
      assert result.from == %{key_code: "x"}
      assert [%{shell_command: cmd}] = result.to
      assert cmd =~ "open -a 'Emacs'"
    end

    test "generates manipulator for multi-key chord with repeat" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("r"))
        |> Chord.append(Key.new("c"))

      command = Command.new(chord, :raycast, "confetti", repeat: true)
      ic = InvokeCommand.new(command)

      result = ToManipulator.manipulator(ic)

      assert result.type == :basic
      assert result.from == %{key_code: "c"}
      assert [%{type: :variable_if, name: var_name, value: 1}] = result.conditions
      assert var_name == "karabinex_r_map"
    end

    test "generates manipulator for multi-key chord without repeat" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("r"))
        |> Chord.append(Key.new("c"))

      command = Command.new(chord, :raycast, "confetti", repeat: false)
      ic = InvokeCommand.new(command)

      result = ToManipulator.manipulator(ic)

      assert result.type == :basic
      assert result.from == %{key_code: "c"}

      assert Enum.any?(result.to, fn
               %{set_variable: %{name: _, type: "unset"}} -> true
               _ -> false
             end)
    end
  end
end
