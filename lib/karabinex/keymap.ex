defmodule Karabinex.Keymap do
  alias Karabinex.Command

  @type spec :: %{String.t() => Command.spec() | spec()}

  defstruct [:key, prefix: [], commands: []]

  def new(key, prefix, commands) do
    %__MODULE__{
      key: key,
      prefix: prefix,
      commands: commands
    }
  end
end
