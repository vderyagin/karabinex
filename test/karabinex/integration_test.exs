defmodule Karabinex.Integration.FixturesTest do
  use ExUnit.Case

  alias Karabinex.JsonConfig

  @fixtures_dir Path.expand("../fixtures", __DIR__)

  @type json_map :: %{optional(String.t()) => term()}
  @type multiset(t) :: %{optional(t) => non_neg_integer()}
  @type fixture_node ::
          {:command, json_map()}
          | {:keymap, String.t(), json_map(), multiset(fixture_node()), multiset(json_map()),
             json_map()}

  test "fixtures" do
    cases = fixture_cases()

    assert cases != []

    Enum.each(cases, fn %{name: name, input_path: input_path, expected_path: expected_path} ->
      assert File.exists?(input_path)
      assert File.exists?(expected_path)

      actual =
        input_path
        |> File.read!()
        |> JsonConfig.parse_json!()
        |> Karabinex.to_manipulators()
        |> to_json_list()
        |> parse_nodes()

      expected =
        expected_path
        |> File.read!()
        |> Jason.decode!()
        |> parse_nodes()

      case compare_multisets(actual, expected) do
        :ok ->
          :ok

        {:error, message} ->
          flunk("fixture mismatch: #{name}\n#{message}")
      end
    end)
  end

  @spec fixture_cases() :: [map()]
  defp fixture_cases do
    @fixtures_dir
    |> Path.join("*_input.json")
    |> Path.wildcard()
    |> Enum.map(fn input_path ->
      base =
        input_path
        |> Path.basename("_input.json")

      %{
        name: base,
        input_path: input_path,
        expected_path: Path.join(@fixtures_dir, "#{base}_expected.json")
      }
    end)
  end

  @spec to_json_list([term()]) :: [term()]
  defp to_json_list(manipulators) do
    manipulators
    |> Jason.encode!()
    |> Jason.decode!()
  end

  @spec parse_nodes([json_map()]) :: multiset(fixture_node())
  defp parse_nodes(manipulators) when is_list(manipulators) do
    {nodes, []} = parse_sequence(manipulators)
    to_multiset(nodes)
  end

  @spec parse_sequence([json_map()]) :: {[fixture_node()], [json_map()]}
  defp parse_sequence(manipulators), do: parse_sequence(manipulators, [])

  defp parse_sequence([], acc), do: {Enum.reverse(acc), []}

  defp parse_sequence([manipulator | rest], acc) do
    case enable_var_name(manipulator) do
      nil ->
        node = {:command, normalize_manipulator(manipulator)}
        parse_sequence(rest, [node | acc])

      var_name ->
        {node, tail} = parse_keymap(manipulator, rest, var_name)
        parse_sequence(tail, [node | acc])
    end
  end

  @spec parse_keymap(json_map(), [json_map()], String.t()) :: {fixture_node(), [json_map()]}
  defp parse_keymap(enable_manipulator, rest, var_name) do
    {children, remaining, captures} = parse_children_and_captures(rest, var_name, [], [])

    case remaining do
      [disable_manipulator | tail] ->
        if disable_var_name(disable_manipulator) != var_name do
          raise "Expected disable for #{var_name}"
        end

        node = {
          :keymap,
          var_name,
          normalize_manipulator(enable_manipulator),
          to_multiset(children),
          to_multiset(captures),
          normalize_manipulator(disable_manipulator)
        }

        {node, tail}

      [] ->
        raise "Missing disable for #{var_name}"
    end
  end

  @spec parse_children_and_captures([json_map()], String.t(), [fixture_node()], [json_map()]) ::
          {[fixture_node()], [json_map()], [json_map()]}
  defp parse_children_and_captures([], var_name, _children, _captures) do
    raise "Missing disable for #{var_name}"
  end

  defp parse_children_and_captures([manipulator | rest], var_name, children_acc, captures_acc) do
    cond do
      disable_var_name(manipulator) == var_name ->
        {Enum.reverse(children_acc), [manipulator | rest], Enum.reverse(captures_acc)}

      capture_var_name(manipulator) == var_name ->
        {captures, remaining} = parse_captures([manipulator | rest], var_name, captures_acc)
        {Enum.reverse(children_acc), remaining, Enum.reverse(captures)}

      (child_var = enable_var_name(manipulator)) != nil ->
        {child_node, remaining} = parse_keymap(manipulator, rest, child_var)

        parse_children_and_captures(
          remaining,
          var_name,
          [child_node | children_acc],
          captures_acc
        )

      true ->
        child_node = {:command, normalize_manipulator(manipulator)}
        parse_children_and_captures(rest, var_name, [child_node | children_acc], captures_acc)
    end
  end

  @spec parse_captures([json_map()], String.t(), [json_map()]) :: {[json_map()], [json_map()]}
  defp parse_captures([], var_name, _acc) do
    raise "Missing disable for #{var_name}"
  end

  defp parse_captures([manipulator | rest], var_name, acc) do
    cond do
      capture_var_name(manipulator) == var_name ->
        parse_captures(rest, var_name, [normalize_manipulator(manipulator) | acc])

      disable_var_name(manipulator) == var_name ->
        {Enum.reverse(acc), [manipulator | rest]}

      true ->
        raise "Unexpected manipulator in capture block for #{var_name}"
    end
  end

  @spec to_multiset([term()]) :: multiset(term())
  defp to_multiset(list) do
    Enum.reduce(list, %{}, fn item, acc ->
      Map.update(acc, item, 1, &(&1 + 1))
    end)
  end

  @spec compare_multisets(multiset(fixture_node()), multiset(fixture_node())) ::
          :ok | {:error, String.t()}
  defp compare_multisets(actual, expected) when actual == expected, do: :ok

  defp compare_multisets(actual, expected) do
    missing = multiset_diff(expected, actual)
    extra = multiset_diff(actual, expected)

    details =
      []
      |> append_diff("missing", missing)
      |> append_diff("extra", extra)
      |> append_keymap_mismatches(missing, extra)

    {:error, Enum.join(details, "\n")}
  end

  @spec multiset_diff(multiset(fixture_node()), multiset(fixture_node())) ::
          multiset(fixture_node())
  defp multiset_diff(left, right) do
    Enum.reduce(left, %{}, fn {item, count}, acc ->
      remaining = count - Map.get(right, item, 0)

      if remaining > 0 do
        Map.put(acc, item, remaining)
      else
        acc
      end
    end)
  end

  @spec append_diff([String.t()], String.t(), multiset(fixture_node())) :: [String.t()]
  defp append_diff(lines, _label, diff) when diff == %{}, do: lines

  defp append_diff(lines, label, diff) do
    entries =
      diff
      |> Enum.map(fn {item, count} -> "#{count}x #{describe_node(item)}" end)
      |> Enum.join("\n  ")

    lines ++ ["#{label}:\n  #{entries}"]
  end

  @spec append_keymap_mismatches(
          [String.t()],
          multiset(fixture_node()),
          multiset(fixture_node())
        ) ::
          [String.t()]
  defp append_keymap_mismatches(lines, missing, extra) do
    missing_vars = keymap_var_names(missing)
    extra_vars = keymap_var_names(extra)

    mismatched =
      MapSet.intersection(missing_vars, extra_vars)
      |> MapSet.to_list()

    case mismatched do
      [] ->
        lines

      vars ->
        vars_label = Enum.join(vars, ", ")
        lines ++ ["keymap structure mismatch: #{vars_label}"]
    end
  end

  @spec keymap_var_names(multiset(fixture_node())) :: MapSet.t(String.t())
  defp keymap_var_names(diff) do
    Enum.reduce(diff, MapSet.new(), fn
      {{:keymap, var_name, _enable, _children, _captures, _disable}, _count}, acc ->
        MapSet.put(acc, var_name)

      _, acc ->
        acc
    end)
  end

  @spec describe_node(fixture_node()) :: String.t()
  defp describe_node({:keymap, var_name, _enable, children, captures, _disable}) do
    "keymap #{var_name} (children=#{multiset_size(children)}, captures=#{multiset_size(captures)})"
  end

  defp describe_node({:command, manipulator}) do
    from = Map.get(manipulator, "from")

    cond do
      (cmd = first_shell_command(manipulator)) != nil ->
        "command shell_command=#{inspect(cmd)} from=#{inspect(from)}"

      (set_var = first_set_variable(manipulator)) != nil ->
        "command set_variable=#{inspect(set_var)} from=#{inspect(from)}"

      true ->
        "command from=#{inspect(from)}"
    end
  end

  @spec multiset_size(multiset(term())) :: non_neg_integer()
  defp multiset_size(multiset) do
    Enum.reduce(multiset, 0, fn {_item, count}, acc -> acc + count end)
  end

  @spec first_shell_command(json_map()) :: String.t() | nil
  defp first_shell_command(%{"to" => to}) when is_list(to) do
    case Enum.find(to, &Map.has_key?(&1, "shell_command")) do
      %{"shell_command" => cmd} -> cmd
      _ -> nil
    end
  end

  defp first_shell_command(_), do: nil

  @spec first_set_variable(json_map()) :: json_map() | nil
  defp first_set_variable(%{"to" => to}) when is_list(to) do
    case Enum.find(to, &Map.has_key?(&1, "set_variable")) do
      %{"set_variable" => set_var} -> set_var
      _ -> nil
    end
  end

  defp first_set_variable(_), do: nil

  @spec normalize_manipulator(json_map()) :: json_map()
  defp normalize_manipulator(%{} = manipulator) do
    manipulator
    |> normalize_term()
    |> normalize_conditions()
    |> normalize_mandatory_modifiers()
  end

  @spec normalize_term(term()) :: term()
  defp normalize_term(%{} = map) do
    map
    |> Enum.map(fn {key, value} -> {key, normalize_term(value)} end)
    |> Map.new()
  end

  defp normalize_term(list) when is_list(list), do: Enum.map(list, &normalize_term/1)
  defp normalize_term(value), do: value

  @spec normalize_conditions(json_map()) :: json_map()
  defp normalize_conditions(%{"conditions" => conditions} = manipulator)
       when is_list(conditions) do
    Map.put(manipulator, "conditions", to_multiset(conditions))
  end

  defp normalize_conditions(manipulator), do: manipulator

  @spec normalize_mandatory_modifiers(json_map()) :: json_map()
  defp normalize_mandatory_modifiers(
         %{"from" => %{"modifiers" => %{"mandatory" => mandatory} = modifiers} = from} =
           manipulator
       )
       when is_list(mandatory) do
    modifiers = Map.put(modifiers, "mandatory", MapSet.new(mandatory))
    from = Map.put(from, "modifiers", modifiers)
    Map.put(manipulator, "from", from)
  end

  defp normalize_mandatory_modifiers(manipulator), do: manipulator

  @spec enable_var_name(json_map()) :: String.t() | nil
  defp enable_var_name(%{"to" => to}) when is_list(to) do
    case Enum.find(to, &set_variable_value?/1) do
      %{"set_variable" => %{"name" => name, "value" => value}}
      when is_binary(name) and is_number(value) ->
        name

      _ ->
        nil
    end
  end

  defp enable_var_name(_), do: nil

  @spec set_variable_value?(term()) :: boolean()
  defp set_variable_value?(%{"set_variable" => %{"name" => name, "value" => value}})
       when is_binary(name) and is_number(value),
       do: true

  defp set_variable_value?(_), do: false

  @spec disable_var_name(json_map()) :: String.t() | nil
  defp disable_var_name(%{
         "from" => %{"any" => "key_code"},
         "conditions" => conditions,
         "to" => to
       })
       when is_list(conditions) and is_list(to) do
    names =
      conditions
      |> Enum.filter(&variable_if_value?(&1, 1))
      |> Enum.map(& &1["name"])
      |> Enum.uniq()

    case names do
      [name] ->
        if unset_variable_for?(to, name), do: name, else: nil

      _ ->
        nil
    end
  end

  defp disable_var_name(_), do: nil

  @spec capture_var_name(json_map()) :: String.t() | nil
  defp capture_var_name(%{
         "from" => %{"key_code" => code},
         "to" => [%{"key_code" => code}],
         "conditions" => conditions
       })
       when is_list(conditions) do
    if String.starts_with?(code, "left_") or String.starts_with?(code, "right_") do
      names =
        conditions
        |> Enum.filter(&variable_if_value?(&1, 1))
        |> Enum.map(& &1["name"])
        |> Enum.uniq()

      case names do
        [name] -> name
        _ -> nil
      end
    end
  end

  defp capture_var_name(_), do: nil

  @spec variable_if_value?(term(), term()) :: boolean()
  defp variable_if_value?(
         %{"type" => "variable_if", "name" => <<_::binary>>, "value" => expected},
         expected
       ),
       do: true

  defp variable_if_value?(_condition, _expected), do: false

  @spec unset_variable_for?([term()], String.t()) :: boolean()
  defp unset_variable_for?(clauses, name) do
    Enum.any?(clauses, &match?(%{"set_variable" => %{"name" => ^name, "type" => "unset"}}, &1))
  end
end
