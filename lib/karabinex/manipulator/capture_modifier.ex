defmodule Karabinex.Manipulator.CaptureModifier do
  alias Karabinex.{Manipulator, Chord}

  import Manipulator.DSL

  def new(modifier_key_code, chord) do
    %{key_code: modifier_key_code}
    |> manipulate()
    |> remap(%{key_code: modifier_key_code})
    |> if_variable(Chord.var_name(chord))
    |> unset_variable_after_key_up(Chord.var_name(chord))
  end
end
