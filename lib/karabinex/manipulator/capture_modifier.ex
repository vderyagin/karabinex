defmodule Karabinex.Manipulator.CaptureModifier do
  alias Karabinex.{ToManipulator, Manipulator, Chord}

  import Manipulator.DSL

  defstruct [:modifier, :chord, unset_on_key_up: true]

  @type t :: %__MODULE__{
          modifier: String.t(),
          chord: Chord.t(),
          unset_on_key_up: boolean()
        }

  @spec new(String.t(), Chord.t(), boolean()) :: t()
  def new(modifier, chord, unset_on_key_up \\ true) do
    %__MODULE__{
      modifier: modifier,
      chord: chord,
      unset_on_key_up: unset_on_key_up
    }
  end

  defimpl ToManipulator do
    def manipulator(%Manipulator.CaptureModifier{
          modifier: modifier,
          chord: chord,
          unset_on_key_up: unset_on_key_up
        }) do
      var_name = Chord.var_name(chord)

      %{key_code: modifier}
      |> manipulate()
      |> remap(%{key_code: modifier})
      |> if_variable(var_name)
      |> maybe_unset_variable_after_key_up(var_name, unset_on_key_up)
    end

    defp maybe_unset_variable_after_key_up(m, var_name, true) do
      unset_variable_after_key_up(m, var_name)
    end

    defp maybe_unset_variable_after_key_up(m, _var_name, false), do: m
  end
end
