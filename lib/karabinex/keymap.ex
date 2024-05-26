defmodule Karabinex.Keymap do
  alias Karabinex.{Command, Chord}

  defstruct [:chord, :hook, children: []]

  @type binding :: atom() | String.t()
  @type spec :: %{binding() => Command.spec() | spec()}

  @type t :: %__MODULE__{
          chord: Chord.t(),
          children: [t() | Command.t()]
        }

  @spec new(Chord.t(), [t() | Command.t()]) :: t()
  def new(chord, children) do
    %__MODULE__{
      chord: chord,
      children: children
    }
  end

  @spec add_hook(t(), Command.t()) :: t()
  def add_hook(%__MODULE__{} = keymap, %Command{} = hook) do
    %{keymap | hook: hook}
  end
end
