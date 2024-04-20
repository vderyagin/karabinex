defmodule Karabinex.Key do
  alias Karabinex.State

  defstruct raw: nil,
            code: nil,
            modifiers: %{
              command: false,
              shift: false,
              option: false,
              control: false
            }

  @type modifier ::
          :command
          | :shift
          | :option
          | :control

  @type key_code_type ::
          :regular
          | :consumer
          | :pointer

  @type code :: {key_code_type(), String.t()}

  @type t :: %__MODULE__{
          raw: String.t(),
          code: code(),
          modifiers: %{modifier() => boolean()}
        }

  def new(key) do
    %__MODULE__{raw: key}
    |> parse(key)
  end

  def set_code(%__MODULE__{code: nil} = key, code) do
    %{key | code: code}
  end

  def set_modifier(%__MODULE__{modifiers: %{command: false} = mods} = key, :command) do
    %{key | modifiers: %{mods | command: true}}
  end

  def set_modifier(%__MODULE__{modifiers: %{shift: false} = mods} = key, :shift) do
    %{key | modifiers: %{mods | shift: true}}
  end

  def set_modifier(%__MODULE__{modifiers: %{option: false} = mods} = key, :option) do
    %{key | modifiers: %{mods | option: true}}
  end

  def set_modifier(%__MODULE__{modifiers: %{control: false} = mods} = key, :control) do
    %{key | modifiers: %{mods | control: true}}
  end

  def set_modifiers(%__MODULE__{} = key, [first | rest]) do
    key
    |> set_modifier(first)
    |> set_modifiers(rest)
  end

  def set_modifiers(%__MODULE__{} = key, []), do: key

  def parse(%__MODULE__{} = key, "H-" <> rest), do: parse(key, "✦-" <> rest)

  def parse(%__MODULE__{} = key, "✦-" <> rest) do
    key
    |> set_modifiers([:command, :shift, :option, :control])
    |> parse(rest)
  end

  def parse(%__MODULE__{} = key, "⌘-" <> rest) do
    key
    |> set_modifier(:command)
    |> parse(rest)
  end

  def parse(%__MODULE__{} = key, "M-" <> rest), do: parse(key, "⌥-" <> rest)

  def parse(%__MODULE__{} = key, "⌥-" <> rest) do
    key
    |> set_modifier(:option)
    |> parse(rest)
  end

  def parse(%__MODULE__{} = key, "^-" <> rest), do: parse(key, "C-" <> rest)

  def parse(%__MODULE__{} = key, "C-" <> rest) do
    key
    |> set_modifier(:control)
    |> parse(rest)
  end

  def parse(%__MODULE__{} = key, "S-" <> rest) do
    key
    |> set_modifier(:shift)
    |> parse(rest)
  end

  def parse(%__MODULE__{raw: raw} = key, key_code) do
    codes = State.get(:key_codes)

    code_type =
      cond do
        MapSet.member?(codes[:regular], key_code) -> :regular
        MapSet.member?(codes[:consumer], key_code) -> :consumer
        MapSet.member?(codes[:pointer], key_code) -> :pointer
        true -> raise "key code not recognized: #{raw}"
      end

    key
    |> set_code({code_type, key_code})
  end

  def from_object(%__MODULE__{code: {:regular, code}, modifiers: modifiers}) do
    mandatory_modifiers =
      modifiers
      |> Enum.filter(fn {_k, v} -> v end)
      |> Enum.map(fn {k, _v} -> k end)

    %{
      from:
        %{
          key_code: code
        }
        |> Map.merge(
          if Enum.empty?(mandatory_modifiers) do
            %{}
          else
            %{
              modifiers: %{
                mandatory: mandatory_modifiers
              }
            }
          end
        )
    }
  end
end
