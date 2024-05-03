defmodule Karabinex.Command do
  alias Karabinex.Chord

  defstruct [:kind, :arg, :chord, :repeat]

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
          repeat: :key | :keymap | nil
        }

  def new(chord, kind, arg, opts \\ []) do
    %__MODULE__{
      chord: chord,
      kind: kind,
      arg: arg
    }
    |> add_opts(opts)
  end

  def add_opts(%__MODULE__{} = command, [{:repeat, :key} | rest]) do
    %{command | repeat: :key}
    |> add_opts(rest)
  end

  def add_opts(%__MODULE__{} = command, [{:repeat, :keymap} | rest]) do
    %{command | repeat: :keymap}
    |> add_opts(rest)
  end

  def add_opts(%__MODULE__{} = command, []), do: command
end
