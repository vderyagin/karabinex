defmodule Karabinex.Manipulator.EnableKeymap do
  alias Karabinex.{Chord, Manipulator}

  require Chord

  def new(chord) when Chord.singleton?(chord) do
    %{
      type: :basic,
      from: Manipulator.make_from(Chord.last(chord)),
      to: [
        %{
          set_variable: %{
            name: Chord.var_name(chord),
            value: 1
          }
        }
      ]
    }
  end

  def new(chord) do
    %{
      type: :basic,
      from: Manipulator.make_from(Chord.last(chord)),
      to: [
        %{
          set_variable: %{
            name: Chord.var_name(chord),
            value: 1
          }
        },
        %{
          set_variable: %{
            name: Chord.prefix_var_name(chord),
            value: 0
          }
        }
      ],
      conditions: [
        %{
          type: :variable_if,
          name: Chord.prefix_var_name(chord),
          value: 1
        }
      ]
    }
  end
end
