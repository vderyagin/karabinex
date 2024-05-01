defmodule Karabinex.Manipulator.CaptureModifier do
  alias Karabinex.Chord

  def new(modifier_key_code, chord) do
    %{
      type: :basic,
      from: %{
        key_code: modifier_key_code
      },
      to: [
        %{
          key_code: modifier_key_code
        }
      ],
      to_after_key_up: [
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
