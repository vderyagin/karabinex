defmodule Karabinex.Command do
  alias Karabinex.Chord

  defstruct [:kind, :arg, :chord, repeat: false]

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
          {:if, map()}
          | {:repeat, boolean()}

  @type t :: %__MODULE__{
          chord: Chord.t(),
          kind: kind(),
          arg: String.t(),
          repeat: boolean()
        }

  def new(chord, kind, arg, opts \\ []) do
    %__MODULE__{
      chord: chord,
      kind: kind,
      arg: arg
    }
    |> add_opts(opts)
  end

  def add_opts(%__MODULE__{} = command, [{:repeat, value} | rest]) do
    %{command | repeat: value}
    |> add_opts(rest)
  end

  def add_opts(%__MODULE__{} = command, []), do: command
end
