defmodule Karabinex.Command do
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

  defstruct [:kind, :arg, :opts, :key, :prefix]

  def new(kind, arg, key, prefix, opts \\ []) do
    %__MODULE__{
      kind: kind,
      arg: arg,
      key: key,
      prefix: prefix,
      opts: opts
    }
  end
end
