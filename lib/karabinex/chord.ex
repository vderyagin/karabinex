defmodule Karabinex.Chord do
  alias Karabinex.Key

  defstruct keys: []

  @type t :: %__MODULE__{
          keys: [Key.t()]
        }

  defguard singleton?(chord)
           when chord.__struct__ == __MODULE__ and
                  is_map_key(chord, :keys) and
                  is_list(chord.keys) and
                  is_map(hd(chord.keys)) and
                  tl(chord.keys) === []

  @spec new :: t()
  def new do
    %__MODULE__{}
  end

  @spec append(t(), Key.t()) :: t()
  def append(%__MODULE__{keys: keys} = chord, key) do
    %{chord | keys: keys ++ [key]}
  end

  @spec last(t()) :: Key.t()
  def last(%__MODULE__{keys: keys}), do: List.last(keys)

  @spec prefix(t()) :: t()
  def prefix(%__MODULE__{keys: keys}), do: %__MODULE__{keys: Enum.drop(keys, -1)}

  @spec var_name(t()) :: String.t()
  def var_name(%__MODULE__{keys: keys}) do
    "karabinex_"
    |> Kernel.<>(
      keys
      |> Enum.map(&Key.readable_name/1)
      |> Enum.join("_")
    )
    |> Kernel.<>("_map")
  end

  @spec prefix_var_name(t()) :: String.t()
  def prefix_var_name(chord) when not singleton?(chord) do
    chord
    |> prefix()
    |> var_name()
  end
end
