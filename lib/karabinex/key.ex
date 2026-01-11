defmodule Karabinex.Key do
  alias Karabinex.State

  defstruct raw: nil,
            code: nil,
            modifiers: MapSet.new()

  @type modifier ::
          :command
          | :option
          | :control
          | :shift

  @type key_code_type ::
          :regular
          | :consumer
          | :pointer

  @type code :: {key_code_type(), String.t()}

  @type t :: %__MODULE__{
          raw: String.t(),
          code: code() | nil,
          modifiers: MapSet.t(modifier())
        }

  @spec has_modifiers?(t()) :: boolean()
  def has_modifiers?(%__MODULE__{modifiers: modifiers}) do
    MapSet.size(modifiers) > 0
  end

  @spec new(atom() | String.t()) :: t()
  def new(key) do
    raw_key = to_string(key)

    struct(__MODULE__, raw: raw_key, modifiers: MapSet.new())
    |> parse(raw_key)
  end

  @spec set_code(t(), code()) :: t()
  def set_code(%__MODULE__{code: nil} = key, code) do
    %{key | code: code}
  end

  @spec set_modifier(t(), modifier()) :: t() | no_return()
  defp set_modifier(%__MODULE__{modifiers: modifiers} = key, modifier) do
    if MapSet.member?(modifiers, modifier) do
      raise("invalid key specification: #{key.raw}")
    end

    %{key | modifiers: MapSet.put(modifiers, modifier)}
  end

  @spec parse(t(), String.t()) :: t() | no_return()
  def parse(%__MODULE__{} = key, "H-" <> rest), do: parse(key, "✦-" <> rest)
  def parse(%__MODULE__{} = key, "✦-" <> rest), do: parse(key, "⌘-M-C-S-" <> rest)

  def parse(%__MODULE__{} = key, "Meh-" <> rest), do: parse(key, "M-C-S-" <> rest)

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

  @spec code(t()) :: map()
  def code(%__MODULE__{code: {:regular, code}}), do: %{key_code: code}
  def code(%__MODULE__{code: {:consumer, code}}), do: %{consumer_key_code: code}
  def code(%__MODULE__{code: {:pointer, code}}), do: %{pointing_button: code}

  @spec hyper?(t()) :: boolean
  defp hyper?(%__MODULE__{modifiers: modifiers}) do
    MapSet.equal?(modifiers, MapSet.new([:command, :option, :control, :shift]))
  end

  @spec super?(t()) :: boolean
  defp super?(%__MODULE__{modifiers: modifiers}) do
    MapSet.equal?(modifiers, MapSet.new([:option, :control, :shift]))
  end

  @spec readable_name(t()) :: String.t()
  def readable_name(%__MODULE__{code: {_kind, code}, modifiers: modifiers} = key) do
    cond do
      hyper?(key) ->
        "hyper-"

      super?(key) ->
        "meh-"

      true ->
        modifiers
        |> Enum.map(&"#{&1}-")
        |> Enum.join()
    end
    |> Kernel.<>(code)
  end
end
