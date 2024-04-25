defmodule Karabinex.Command do
  alias Karabinex.Chord

  defstruct [:kind, :arg, :opts, :chord]

  @type kind ::
          :app
          | :quit
          | :kill
          | :sh
          | :remap
          | :raycast

  @type spec ::
          {kind(), String.t()}
          | {kind(), String.t(), [option()]}

  @type option ::
          {:if, any()}
          | {:repeat, :key | :keymap}

  @type t :: %__MODULE__{
          kind: kind(),
          arg: String.t(),
          opts: [option()],
          chord: Chord.t()
        }

  def new(kind, arg, chord, opts \\ []) do
    %__MODULE__{
      kind: kind,
      arg: arg,
      chord: chord,
      opts: opts
    }
  end
end
