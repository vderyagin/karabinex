defmodule Karabinex.Manipulator.CaptureModifier do
  alias Karabinex.{Manipulator, Chord}

  import Manipulator.DSL

  def new(modifier_key_code, chord) do
    var_name = Chord.var_name(chord)

    %{key_code: modifier_key_code}
    |> manipulate()
    |> remap(%{key_code: modifier_key_code})
    |> if_variable(var_name)
    |> unset_variable_after_key_up(var_name)
  end
end
