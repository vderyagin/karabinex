defmodule Karabinex.KarabinerConfig do
  @type json_map :: %{optional(String.t()) => term()}
  @type rule :: json_map()
  @type rules :: [rule()]

  @karabiner_config_path "~/.config/karabiner/karabiner.json"
  @karabinex_rules_path "karabinex.json"

  @spec update() :: :ok
  def update do
    rules = read_rules!(@karabinex_rules_path)
    config_path = Path.expand(@karabiner_config_path)
    config = read_json!(config_path)
    updated = replace_rules_in_config(config, rules)

    if updated == config do
      :ok
    else
      write_json!(config_path, updated)
    end
  end

  @spec read_rules!(Path.t()) :: rules()
  defp read_rules!(path) do
    case read_json!(path) do
      %{"rules" => rules} when is_list(rules) and rules != [] ->
        rules

      %{"rules" => []} ->
        raise "karabinex.json has no rules"

      _ ->
        raise "karabinex.json missing rules"
    end
  end

  @spec read_json!(Path.t()) :: json_map()
  defp read_json!(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end

  @spec write_json!(Path.t(), json_map()) :: :ok
  defp write_json!(path, data) do
    File.write!(path, Jason.encode!(data, pretty: true))
  end

  @spec replace_rules_in_config(json_map(), rules()) :: json_map()
  def replace_rules_in_config(%{"profiles" => profiles} = config, new_rules)
      when is_list(profiles) do
    updated_profiles = Enum.map(profiles, &replace_rules_in_profile(&1, new_rules))
    %{config | "profiles" => updated_profiles}
  end

  def replace_rules_in_config(_config, _new_rules) do
    raise "Karabiner config missing profiles"
  end

  @spec replace_rules_in_profile(json_map(), rules()) :: json_map()
  defp replace_rules_in_profile(
         %{"complex_modifications" => %{"rules" => rules} = complex} = profile,
         new_rules
       )
       when is_list(rules) do
    case replace_rules(rules, new_rules) do
      {updated_rules, true} ->
        %{profile | "complex_modifications" => %{complex | "rules" => updated_rules}}

      {_rules, false} ->
        profile
    end
  end

  defp replace_rules_in_profile(profile, _new_rules), do: profile

  @spec replace_rules([json_map()], rules()) :: {[json_map()], boolean()}
  defp replace_rules(existing_rules, new_rules) do
    descriptions =
      new_rules
      |> Enum.map(&Map.get(&1, "description"))
      |> Enum.filter(&is_binary/1)
      |> MapSet.new()

    if MapSet.size(descriptions) == 0 do
      raise "karabinex.json rules missing descriptions"
    end

    {rev, inserted?} =
      Enum.reduce(existing_rules, {[], false}, fn rule, {acc, inserted?} ->
        description = Map.get(rule, "description")

        if MapSet.member?(descriptions, description) do
          if inserted? do
            {acc, true}
          else
            {Enum.reverse(new_rules, acc), true}
          end
        else
          {[rule | acc], inserted?}
        end
      end)

    if inserted? do
      {Enum.reverse(rev), true}
    else
      {existing_rules, false}
    end
  end
end
