defmodule Karabinex.Keymap do
  alias Karabinex.{Command, Chord}

  defstruct [:chord, children: []]

  @type binding :: atom() | String.t()
  @type spec :: %{binding() => Command.spec() | spec()}

  @type t :: %__MODULE__{
          chord: Chord.t(),
          children: [t() | Command.t()]
        }

  def new(chord, children) do
    %__MODULE__{
      chord: chord,
      children: children
    }
  end
end
