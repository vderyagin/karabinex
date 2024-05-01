defmodule Karabinex.Manipulator.DisableKeymap do
  alias Karabinex.Chord

  def new(chord) do
    %{
      type: :basic,
      from: %{
        any: :key_code
      },
      to: [
        %{
          set_variable: %{
            name: Chord.var_name(chord),
            value: 0
          }
        }
      ],
      conditions: [
        %{
          type: :variable_if,
          name: Chord.var_name(chord),
          value: 1
        }
      ]
    }
  end
end
