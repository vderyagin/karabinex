defmodule Karabinex.Manipulator.CaptureModifier do
  alias Karabinex.{ToManipulator, Manipulator, Chord}

  import Manipulator.DSL

  defstruct [:modifier, :chord]

  @type t :: %__MODULE__{
          modifier: String.t(),
          chord: Chord.t()
        }

  @spec new(String.t(), Chord.t()) :: t()
  def new(modifier, chord), do: %__MODULE__{modifier: modifier, chord: chord}

  defimpl ToManipulator do
    def manipulator(%Manipulator.CaptureModifier{modifier: modifier, chord: chord}) do
      var_name = Chord.var_name(chord)

      %{key_code: modifier}
      |> manipulate()
      |> remap(%{key_code: modifier})
      |> if_variable(var_name)
      |> unset_variable_after_key_up(var_name)
    end
  end
end
