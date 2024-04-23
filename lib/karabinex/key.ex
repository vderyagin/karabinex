defmodule Karabinex.Key do
  alias Karabinex.State

  defstruct raw: nil,
            code: nil,
            modifiers: []

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
          modifiers: [modifier()]
        }

  def new(key) do
    raw_key = to_string(key)

    %__MODULE__{raw: raw_key}
    |> parse(raw_key)
  end

  def set_code(%__MODULE__{code: nil} = key, code) do
    %{key | code: code}
  end

  def set_modifier(%__MODULE__{modifiers: modifiers} = key, :command) do
    if :command in modifiers, do: raise("invalid key specification: #{key.raw}")
    %{key | modifiers: [:command | modifiers]}
  end

  def set_modifier(%__MODULE__{modifiers: modifiers} = key, :shift) do
    if :shift in modifiers, do: raise("invalid key specification: #{key.raw}")
    %{key | modifiers: [:shift | modifiers]}
  end

  def set_modifier(%__MODULE__{modifiers: modifiers} = key, :option) do
    if :option in modifiers, do: raise("invalid key specification: #{key.raw}")
    %{key | modifiers: [:option | modifiers]}
  end

  def set_modifier(%__MODULE__{modifiers: modifiers} = key, :control) do
    if :control in modifiers, do: raise("invalid key specification: #{key.raw}")
    %{key | modifiers: [:control | modifiers]}
  end

  def parse(%__MODULE__{} = key, "H-" <> rest), do: parse(key, "✦-" <> rest)
  def parse(%__MODULE__{} = key, "✦-" <> rest), do: parse(key, "⌘-M-C-S-" <> rest)

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

  def code(%__MODULE__{code: {:regular, code}}), do: %{key_code: code}
  def code(%__MODULE__{code: {:consumer, code}}), do: %{consumer_key_code: code}
  def code(%__MODULE__{code: {:pointer, code}}), do: %{pointing_button: code}
end
