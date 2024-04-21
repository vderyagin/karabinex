defmodule Karabinex.Command do
  alias Karabinex.Key

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
      key: Key.new(key),
      prefix: Enum.map(prefix, &Key.new/1),
      opts: opts
    }
  end
end
