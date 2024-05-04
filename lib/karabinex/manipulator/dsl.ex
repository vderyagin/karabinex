defmodule Karabinex.Manipulator.DSL do
  alias Karabinex.Key

  def from(%{} = m, %Key{modifiers: []} = key) do
    Map.put(m, :from, Key.code(key))
    |> add_type()
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
    |> add_type()
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

  defp add_type(%{type: :basic} = m), do: m
  defp add_type(%{} = m), do: Map.put(m, :type, :basic)
end
