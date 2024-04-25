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
          chord: Chord.t(),
          kind: kind(),
          arg: String.t(),
          opts: [option()]
        }

  def new(chord, kind, arg, opts \\ []) do
    %__MODULE__{
      chord: chord,
      kind: kind,
      arg: arg,
      opts: opts
    }
  end
end
