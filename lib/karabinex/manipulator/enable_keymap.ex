defmodule Karabinex.Manipulator.EnableKeymap do
  alias Karabinex.{Chord, Manipulator, Command}

  import Manipulator.DSL

  require Chord

  def new(chord, nil) when Chord.singleton?(chord) do
    Chord.last(chord)
    |> manipulate()
    |> set_variable(Chord.var_name(chord))
  end

  def new(chord, nil) do
    Chord.last(chord)
    |> manipulate()
    |> if_variable(Chord.prefix_var_name(chord))
    |> unset_variable(Chord.prefix_var_name(chord))
    |> set_variable(Chord.var_name(chord))
  end

  def new(chord, %Command{kind: kind, arg: arg}) do
    chord
    |> new(nil)
    |> run_shell_command(Manipulator.InvokeCommand.command(kind, arg))
  end
end
