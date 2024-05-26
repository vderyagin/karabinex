defmodule Karabinex.Manipulator.DSL do
  alias Karabinex.Key

  def manipulate(key) do
    from(%{type: :basic}, key)
  end

  def from(%{} = m, %Key{modifiers: []} = key) do
    Map.put(m, :from, Key.code(key))
  end

  def from(%{} = m, %Key{modifiers: modifiers} = key) do
    Map.put(
      m,
      :from,
      Key.code(key)
      |> Map.merge(%{
        modifiers: %{
          mandatory: modifiers
        }
      })
    )
  end

  def from(%{} = m, :any) do
    Map.put(m, :from, %{any: :key_code})
  end

  def from(%{} = m, %{key_code: key_code}) do
    Map.put(m, :from, %{key_code: key_code})
  end

  def remap(%{} = m, clause) do
    append_clause(m, :to, clause)
  end

  def run_shell_command(%{} = m, cmd) do
    append_clause(m, :to, %{shell_command: cmd})
  end

  def set_variable(%{} = m, var_name, value \\ 1) do
    append_clause(m, :to, %{
      set_variable: %{
        name: var_name,
        value: value
      }
    })
  end

  def unset_variable(%{} = m, var_name), do: set_variable(m, var_name, 0)

  def unset_variable_after_key_up(m, var_name) do
    append_clause(m, :to_after_key_up, %{
      set_variable: %{
        name: var_name,
        value: 0
      }
    })
  end

  def if_variable(%{} = m, var_name, value \\ 1) do
    append_clause(m, :conditions, %{type: :variable_if, name: var_name, value: value})
  end

  def unless_variable(%{} = m, var_name), do: if_variable(m, var_name, 0)

  def unless_variables(%{} = m, []), do: m

  def unless_variables(%{} = m, [var_name | rest]) do
    m
    |> unless_variable(var_name)
    |> unless_variables(rest)
  end

  defp append_clause(%{} = m, key, clause) do
    if Map.has_key?(m, key) do
      update_in(m, [key], &(&1 ++ [clause]))
    else
      Map.put(m, key, [clause])
    end
  end
end
