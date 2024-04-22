defmodule Karabinex.Keymap do
  alias Karabinex.{Command, Key}

  @type binding :: atom() | String.t()
  @type spec :: %{binding() => Command.spec() | spec()}

  defstruct [:key, prefix: [], commands: []]

  def new(key, prefix, commands) do
    %__MODULE__{
      key: Key.new(key),
      prefix: Enum.map(prefix, &Key.new/1),
      commands: commands
    }
  end
end
