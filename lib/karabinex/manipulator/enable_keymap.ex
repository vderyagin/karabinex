defmodule Karabinex.Manipulator.EnableKeymap do
  alias Karabinex.{Chord, ToManipulator, Manipulator, Command, Keymap}

  alias __MODULE__, as: EK

  import Manipulator.DSL
  require Chord

  defstruct [:keymap, other_chords: []]

  @type t :: %__MODULE__{
          keymap: Keymap.t(),
          other_chords: [Chord.t()]
        }

  @spec new(Keymap.t()) :: t()
  def new(%Keymap{} = km), do: %__MODULE__{keymap: km}

  @spec register_other_chords(t(), [Chord.t()]) :: t()
  def register_other_chords(%__MODULE__{keymap: %Keymap{chord: chord}} = ek, chords)
      when Chord.singleton?(chord) do
    %{ek | other_chords: chords}
  end

  def register_other_chords(%__MODULE__{keymap: %Keymap{chord: chord}} = ek, chords) do
    %{ek | other_chords: chords |> Enum.filter(&(&1 != Chord.prefix(chord)))}
  end

  defimpl ToManipulator do
    def manipulator(%EK{
          keymap: %Keymap{chord: chord, hook: nil},
          other_chords: other_chords
        })
        when Chord.singleton?(chord) do
      Chord.last(chord)
      |> manipulate()
      |> unless_variables(Enum.map(other_chords, &Chord.var_name/1))
      |> set_variable(Chord.var_name(chord))
    end

    def manipulator(%EK{
          keymap: %Keymap{chord: chord, hook: nil},
          other_chords: other_chords
        }) do
      Chord.last(chord)
      |> manipulate()
      |> unless_variables(Enum.map(other_chords, &Chord.var_name/1))
      |> if_variable(Chord.prefix_var_name(chord))
      |> unset_variable(Chord.prefix_var_name(chord))
      |> set_variable(Chord.var_name(chord))
    end

    def manipulator(%EK{
          keymap: %Keymap{
            chord: chord,
            hook: %Command{kind: kind, arg: arg}
          },
          other_chords: other_chords
        }) do
      Chord.last(chord)
      |> manipulate()
      |> unless_variables(Enum.map(other_chords, &Chord.var_name/1))
      |> if_variable(Chord.prefix_var_name(chord))
      |> unset_variable(Chord.prefix_var_name(chord))
      |> set_variable(Chord.var_name(chord))
      |> run_shell_command(Manipulator.InvokeCommand.command(kind, arg))
    end
  end
end
