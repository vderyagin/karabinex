defmodule Karabinex.Manipulator.EnableKeymap do
  alias Karabinex.{Chord, Manipulator}

  import Manipulator.DSL

  require Chord

  def new(chord) when Chord.singleton?(chord) do
    Chord.last(chord)
    |> manipulate()
    |> set_variable(Chord.var_name(chord))
  end

  def new(chord) do
    Chord.last(chord)
    |> manipulate()
    |> if_variable(Chord.prefix_var_name(chord))
    |> unset_variable(Chord.prefix_var_name(chord))
    |> set_variable(Chord.var_name(chord))
  end
end
