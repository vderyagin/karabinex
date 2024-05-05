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

  def remap(%{to: to} = m, clause) when is_list(to) do
    update_in(m.to, &(&1 ++ [clause]))
  end
  def remap(%{} = m, clause) do
    m
    |> Map.put(:to, [])
    |> remap(clause)
  end

  def run_shell_command(%{to: to} = m, cmd) when is_list(to) do
    update_in(m.to, &(&1 ++ [%{shell_command: cmd}]))
  end

  def run_shell_command(%{} = m, cmd) do
    m
    |> Map.put(:to, [])
    |> run_shell_command(cmd)
  end

  def set_variable(m, var_name, value \\ 1)

  def set_variable(%{to: to} = m, var_name, value) when is_list(to) do
    clause =
      %{
        set_variable: %{
          name: var_name,
          value: value
        }
      }

    update_in(m.to, &(&1 ++ [clause]))
  end

  def set_variable(%{} = m, var_name, value) do
    m
    |> Map.put(:to, [])
    |> set_variable(var_name, value)
  end

  def unset_variable(%{} = m, var_name), do: set_variable(m, var_name, 0)

  def unset_variable_after_key_up(%{to_after_key_up: to} = m, var_name) when is_list(to) do
    clause =
      %{
        set_variable: %{
          name: var_name,
          value: 0
        }
      }

    update_in(m.to_after_key_up, &(&1 ++ [clause]))
  end

  def unset_variable_after_key_up(%{} = m, var_name) do
    m
    |> Map.put(:to_after_key_up, [])
    |> unset_variable_after_key_up(var_name)
  end

  def if_variable(m, var_name, value \\ 1)

  def if_variable(%{conditions: conditions} = m, var_name, value) when is_list(conditions) do
    clause = %{
      type: :variable_if,
      name: var_name,
      value: value
    }

    update_in(m.conditions, &(&1 ++ [clause]))
  end

  def if_variable(%{} = m, var_name, value) do
    m
    |> Map.put(:conditions, [])
    |> if_variable(var_name, value)
  end

  def unless_variable(%{} = m, var_name), do: if_variable(m, var_name, 0)
end
