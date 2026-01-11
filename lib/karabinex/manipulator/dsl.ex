defmodule Karabinex.Manipulator.DSL do
  alias Karabinex.Key

  @type manipulator :: %{
          optional(:type) => :basic,
          optional(:from) => map(),
          optional(:to) => [map()],
          optional(:to_after_key_up) => [map()],
          optional(:conditions) => [map()]
        }

  @type from_spec :: Key.t() | :any | %{key_code: String.t()}

  @dialyzer {:nowarn_function, manipulate: 1}
  @spec manipulate(from_spec()) :: manipulator()
  def manipulate(%Key{} = key), do: from(%{type: :basic}, key)
  def manipulate(:any), do: from(%{type: :basic}, :any)
  def manipulate(%{key_code: _} = key), do: from(%{type: :basic}, key)

  @spec from(manipulator(), from_spec()) :: manipulator()
  def from(%{} = m, %Key{modifiers: modifiers} = key) do
    if Key.has_modifiers?(key) do
      Map.put(
        m,
        :from,
        Key.code(key)
        |> Map.merge(%{
          modifiers: %{
            mandatory: MapSet.to_list(modifiers)
          }
        })
      )
    else
      Map.put(m, :from, Key.code(key))
    end
  end

  def from(%{} = m, :any) do
    Map.put(m, :from, %{any: :key_code})
  end

  def from(%{} = m, %{key_code: key_code}) do
    Map.put(m, :from, %{key_code: key_code})
  end

  @spec remap(manipulator(), map()) :: manipulator()
  def remap(%{} = m, clause) do
    append_clause(m, :to, clause)
  end

  @spec run_shell_command(manipulator(), String.t()) :: manipulator()
  def run_shell_command(%{} = m, cmd) do
    append_clause(m, :to, %{shell_command: cmd})
  end

  @spec set_variable(manipulator(), String.t(), integer()) :: manipulator()
  def set_variable(%{} = m, var_name, value \\ 1) do
    append_clause(m, :to, %{
      set_variable: %{
        name: var_name,
        value: value
      }
    })
  end

  @spec unset_variable(manipulator(), String.t()) :: manipulator()
  def unset_variable(%{} = m, var_name) do
    append_clause(m, :to, %{
      set_variable: %{
        name: var_name,
        type: "unset"
      }
    })
  end

  @spec unset_variable_after_key_up(manipulator(), String.t()) :: manipulator()
  def unset_variable_after_key_up(m, var_name) do
    append_clause(m, :to_after_key_up, %{
      set_variable: %{
        name: var_name,
        type: "unset"
      }
    })
  end

  @spec if_variable(manipulator(), String.t(), integer()) :: manipulator()
  def if_variable(%{} = m, var_name, value \\ 1) do
    append_clause(m, :conditions, %{type: :variable_if, name: var_name, value: value})
  end

  @spec unless_variable(manipulator(), String.t()) :: manipulator()
  def unless_variable(%{} = m, var_name), do: if_variable(m, var_name, 0)

  @spec unless_variables(manipulator(), [String.t()]) :: manipulator()
  def unless_variables(%{} = m, []), do: m

  def unless_variables(%{} = m, [var_name | rest]) do
    m
    |> unless_variable(var_name)
    |> unless_variables(rest)
  end

  @spec append_clause(manipulator(), atom(), map()) :: manipulator()
  defp append_clause(%{} = m, key, clause) do
    if Map.has_key?(m, key) do
      update_in(m, [key], &(&1 ++ [clause]))
    else
      Map.put(m, key, [clause])
    end
  end
end
