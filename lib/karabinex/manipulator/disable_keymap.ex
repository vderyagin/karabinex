defmodule Karabinex.Manipulator.DisableKeymap do
  alias Karabinex.{Manipulator, ToManipulator, Chord, Keymap}

  import Manipulator.DSL

  defstruct [:keymap]

  @type t :: %__MODULE__{keymap: Keymap.t()}

  @spec new(Keymap.t()) :: t()
  def new(%Keymap{} = km), do: %__MODULE__{keymap: km}

  defimpl ToManipulator do
    def manipulator(%Manipulator.DisableKeymap{keymap: %Keymap{chord: chord}}) do
      var_name = Chord.var_name(chord)

      manipulate(:any)
      |> if_variable(var_name)
      |> unset_variable(var_name)
    end
  end
end
