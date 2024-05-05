defmodule Karabinex.Manipulator.DisableKeymap do
  alias Karabinex.{Manipulator, Chord}

  import Manipulator.DSL

  def new(chord) do
    var_name = Chord.var_name(chord)

    :any
    |> manipulate()
    |> if_variable(var_name)
    |> unset_variable(var_name)
  end
end
